# $Id: dbf.rb,v 1.9 2006/02/12 22:02:54 aamine Exp $
#
# Copyright (c) 2005,2006 yrock
# 
# This program is free software.
# You can distribute/modify this program under the terms of the Ruby License.
#
# 2006-02-11 refactored by Minero Aoki

module DBF

  class PackedStruct
    class << PackedStruct
      def define(&block)
        c = Class.new(self)
        def c.inherited(subclass)
          proto = @prototypes
          subclass.instance_eval {
            @prototypes = proto
          }
        end
        c.module_eval(&block)
        c
      end

      def char(name)
        define_field name, 'A', 1
      end

      def byte(name)
        define_field name, 'C', 1
      end

      def int16LE(name)
        define_field name, 'v', 2
      end

      def int32LE(name)
        define_field name, 'V', 4
      end

      def string(n, name)
        define_field name, "Z#{n}", n
      end

      private

      def define_field(name, template, size)
        (@prototypes ||= []).push FieldPrototype.new(name, template, size)
        define_accessor name
      end

      def define_accessor(name)
        module_eval(<<-End, __FILE__, __LINE__ + 1)
          def #{name}
            self['#{name}']
          end

          def #{name}=(val)
            self['#{name}'] = val
          end
        End
      end
    end

    class FieldPrototype
      def initialize(name, template, size)
        @name = name
        @template = template
        @size = size
      end

      attr_reader :name
      attr_reader :size

      def read(f)
        parse(f.read(@size))
      end

      def parse(s)
        s.unpack(@template)[0]
      end

      def serialize(val)
        [val].pack(@template)
      end
    end

    def PackedStruct.size
      @prototypes.map {|proto| proto.size }.inject(0) {|sum, s| sum + s }
    end

    def PackedStruct.names
      @prototypes.map {|proto| proto.name }
    end

    def PackedStruct.prototypes
      @prototypes
    end

    def PackedStruct.read(f)
      new(* @prototypes.map {|proto| proto.read(f) })
    end

    def initialize(*vals)
      @alist = self.class.names.zip(vals)
    end

    def inspect
      "\#<#{self.class} #{@alist.map {|n,v| "#{n}=#{v.inspect}" }.join(' ')}>"
    end

    def [](name)
      k, v = @alist.assoc(name.to_s.intern)
      raise ArgumentError, "no such field: #{name}" unless k
      v
    end

    def []=(name, val)
      a = @alist.assoc(name.to_s.intern)
      raise ArgumentError, "no such field: #{name}" unless a
      a[1] = val
    end

    def serialize
      self.class.prototypes.zip(@alist.map {|_, val| val })\
          .map {|proto, val| proto.serialize(val) }.join('')
    end
  end


  DBF_VERSION = 3

  # dBASE IV 2.0 file header leading block
  #
  # - filesize = header_size + (record_size * n_records)
  # - header_size = HeaderLead.size + (Field.size * n_Fields) + 1
  #
  HeaderLead = PackedStruct.define {
    byte       :magic        # MSSSmVVV (M: dBASE III+/IV memo file,
                             #           S: SQL table,
                             #           m: dBASE IV memo file,
                             #           V: format version)
    byte       :_year        # last-modifield year
    byte       :month        # last-modifield month
    byte       :date         # last-modifield date
    int32LE    :n_records    # a number of records
    int16LE    :header_size  # byte-size of whole header
    int16LE    :record_size  # byte-size of a record
    string 2,  :reserved1
    byte       :in_transaction
    byte       :encrypted
    string 12, :reserved2
    byte       :mdx          # 0x01: MDX;  0x0: no MDX
    byte       :langid       # language driver ID
    string 2,  :reserved3
  }
  class HeaderLead   # reopen
    def HeaderLead.create
      now = Time.now
      new(DBF_VERSION, now.year, now.month, now.day,
          0, size() + 1, 0,
          "", 0, 0, "", 0, 0, "")
    end

    def version
      magic() | 0b111
    end

    def year
      1900 + _year()
    end

    def year=(y)
      self._year = y - 1900
    end

    def last_modified
      Time.local(year(), month(), date())
    end

    def last_modified=(t)
      self.year = t.year
      self.month = t.month
      self.date = t.day
    end

    def n_fields
      (header_size() - self.class.size() - 1) / Field.size
    end
  end


  class FormatError < StandardError; end

  Field = PackedStruct.define {
    string 11, :name
    char       :type
    string 4,  :reserved1
    byte       :size
    byte       :decimal
    string 2,  :reserved2
    byte       :workingID
    string 10, :reserved3
    byte       :mdx          # 0x0: MDX;  0x1: no MDX
  }
  class Field   # reopen
    # filled by field_type
    TYPE_TO_CLASS = {}

    class << self
      def field_type(ch)
        @type = ch
        TYPE_TO_CLASS[ch] = self
      end

      alias newobj new

      def new(name, type, *args)
        return newobj(name, @type, *args) if self < Field
        c = TYPE_TO_CLASS[type] or
            raise FormatError, "illegal type: #{type.inspect}"
        c.newobj(name, type, *args)
      end
    end

    def initialize(*args)
      super(*args)
      @value = nil
    end

    attr_accessor :value

    def inspect
      "\#<#{self.class} #{@alist.map {|n,v| "#{n}=#{v.inspect}" }.join(' ')} value=#{@value.inspect}>"
    end

    alias serialize_schema serialize
  end

  class NumericField < Field
    field_type 'N'

    def NumericField.new2(name, size, dec)
      new(name, @type, "", size, dec, "", 0, "", 0x0)
    end

    def string_field?
      false
    end

    def serialize_value
      # �㡧sprintf("%8.3f", ...)
      sprintf("%#{size()}.#{decimal()}f", @value)
    end

    def load_value(f)
      @value = f.read(size()).to_f
    end

    def load_default_value
      @value = 0.0
    end
  end

  class FloatField < NumericField
    field_type 'F'
  end

  class StringField < Field
    field_type 'C'

    def StringField.new2(name, size)
      new(name, @type, "", size, 0, "", 0, "", 0x0)
    end

    def string_field?
      true
    end

    def serialize_value
      sprintf("%-#{size()}s", @value)
    end

    def load_value(f)
      @value = f.read(size())
    end

    def load_default_value
      @value = ""
    end
  end


  class RecordSet

    def RecordSet.open(path, mode = 'r')
      recset = new(path, mode)
      if block_given?
        begin
          return yield(recset)
        ensure
          recset.close
        end
      else
        recset
      end
    end

    def initialize(path, mode = 'r')
      @mode = mode
      @idx = 0   # record index (beginning with 0)
      @current = nil
      case mode
      when 'r'
        @f = File.open(path, 'rb+')
        @lead = HeaderLead.read(@f)
        @header_modified = false
        @fields = (0 ... @lead.n_fields).to_a.map { Field.read(@f) }
        set_current_record 0
      when 'c'
        @f = File.open(path, 'wb+')
        @lead = HeaderLead.create
        @header_modified = true
        @fields = []
      else
        raise ArgumentError, "invalid open mode: #{mode.inspect}"
      end
    end

    def close
      if @mode == "c"
        save_header
        seek @lead.n_records
        @f.write EOF
      end
      @f.close
    end

    def size
      @lead.n_records
    end

    #
    # Database Schema
    #

    attr_reader :fields

    def field(name)
      @fields.detect {|f| f.name == name } or
          raise ArgumentError, "no such field: #{name.inspect}"
    end

    def add_numeric_field(name, size, dec)
      add_field NumericField.new2(name, size, dec)
    end

    def add_float_field(name, size, dec)
      add_field FloatField.new2(name, size, dec)
    end

    def add_string_field(name, size)
      add_field StringField.new2(name, size)
    end

    def add_field(f)
      @fields.push f
      schema_modified
    end

    #
    # Record Pointer, Read/Write
    #

    def eof?
      @idx >= @lead.n_records
    end

    def empty?
      @lead.n_records == 0
    end

    def current
      return nil if empty?
      return nil if eof?
      _current()
    end

    def first
      return nil if empty?
      set_current_record 0
      self
    end

    def next
      return nil if eof?
      set_current_record @idx + 1
      self
    end

    def prev
      return nil if @idx == 0
      set_current_record @idx - 1
      self
    end

    def each_record
      until eof?
        yield current()
        self.next
      end
    end

    alias each each_record

    def append
      set_current_record @lead.n_records
      @fields.each do |field|
        field.load_default_value
      end
      if block_given?
        yield _current()
        update
      else
        _current()
      end
    end

    def update
      save_record
      if eof?
        @lead.n_records += 1
        header_modified
      end
    end

    private

    EOH = "\x0d"   # End Of Header
    EOF = "\x1a"   # End Of File

    REC_ALIVE   = " "
    REC_REMOVED = "*"

    def _current
      @current ||= Record.new(@fields)
    end

    def schema_modified
      @current = nil
      @lead.header_size = HeaderLead.size +
                          (Field.size * @fields.size) +
                          EOH.size
      @lead.record_size = REC_ALIVE.size +
                          @fields.inject(0) {|sum, f| sum + f.size }
      header_modified
    end

    def header_modified
      @header_modified = true
    end
    
    def header_modified?
      @header_modified
    end

    def set_current_record(idx)
      @idx = idx
      seek @idx
      return if empty?
      return if eof?
      load_record
    end

    def seek(idx)
      @f.seek pos(@idx), File::SEEK_SET
    end

    # 0 =< idx <= @lead.n_records
    def pos(idx)
      @lead.header_size + @lead.record_size * idx
    end

    def save_header
      return unless header_modified?
      @f.seek 0, File::SEEK_SET
      @lead.last_modified = Time.now
      @f.write @lead.serialize
      @fields.each do |field|
        @f.write field.serialize_schema
      end
      @f.write EOH
      @header_modified = false
    end

    def save_record
      @f.write REC_ALIVE
      @fields.each do |field|
        @f.write field.serialize_value
      end
    end

    def load_record
      @f.read REC_ALIVE.size   # discard ALIVE/REMOVED mark
      @fields.each do |field|
        field.load_value @f
      end
    end

  end


  class Record

    def initialize(fields)
      @fields = fields
      fields.each do |f|
        define_accessor f.name
      end
    end

    def define_accessor(name)
      instance_eval(<<-End, __FILE__, __LINE__ + 1)
        def #{name}
          self["#{name}"]
        end

        def #{name}=(val)
          self["#{name}"] = val
        end
      End
    end
    private :define_accessor

    def inspect
      "\#<#{self.class} #{@fields.map {|f| "#{f.name}(#{f.type})=#{f.value.inspect}" }.join(' ')}>"
    end

    def field(name)
      @fields.detect {|f| f.name == name } or
          raise ArgumentError, "no such field: #{name.inspect}"
    end

    attr_reader :fields

    def [](name)
      field(name).value
    end

    def []=(name, val)
      field(name).value = val
    end

    def names
      @fields.map {|f| f.name }
    end

    def values
      @fields.map {|f| f.value }
    end

  end

end
