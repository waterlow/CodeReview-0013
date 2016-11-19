#!/usr/local/bin/ruby -Ke
#
# $Id: recomb.rb,v 1.4 2006/02/12 22:05:45 aamine Exp $
#
# ����dbf�ե����뤫�顢���ĤΥǥե���ȥե������(�����ȱ���)���Ȥ�
# ȴ���Ф��ƻ��ꤷ���ե�����ɤ�ä���������쥳���ɤȤ���dbf�ե�
# �������Ϥ���
# ���ϥե�����ɤϡ����ϥꥹ�Ȥ���Ƭ�ե������Ʊ̾�ե�����ɤ����
# �Ȥ��롣ʸ�����ե�����ɤ���ϻ��ꤹ��ȡ����Τ����줫���ĤǤ���
# �Τʤ��쥳���ɤ��Ф��Ƥϡ��쥳���ɤ���Ϥ��ʤ�
# ���Ϥϡ����ޥ�ɥ饤��ǻ��ꤷ���ꥹ�ȥե���������ɹ��ࡣ
# ���Ϥϡ����ޥ�ɥ饤��ǻ��ꤷ�����ϥե������³���ƽ񤭹��ࡣ
#
# Example:
# ./recomb.rb -f pntid,name,area -o output.dbf input1.dbf input2.dbf
#

require './dbf'
require 'optparse'

def main
  additional = []
  outfile = nil
  parser = OptionParser.new
  parser.banner = "Usage: #{$0} [-f NAME,NAME...] -o PATH input..."
  parser.on('-f', '--fields=NAME,NAME', 'Adding field names.') {|names|
    additional = names.split(',')
  }
  parser.on('-o', '--output=PATH', 'Name of output file.') {|path|
    outfile = path
  }
  parser.on('--help', 'Prints this message and quit.') {
    puts parser.help
    exit 0
  }
  def parser.error(msg = nil)
    $stderr.puts msg if msg
    $stderr.puts help()
    exit 1
  end
  begin
    parser.parse!
  rescue OptionParser::ParseError => err
    parser.error err.message
  end
  parser.error 'no output file' unless outfile
  parser.error 'no input file' if ARGV.empty?
  infiles = ARGV

  schema_initialized = false
  DBF::RecordSet.open(outfile, 'c') {|dbout|
    infiles.each do |path|
      DBF::RecordSet.open(path, 'r') {|dbin|
        unless schema_initialized
          dbout.add_string_field 'datetime', 20
          dbout.add_numeric_field 'rainfall', 10, 4
          additional.each do |name|
            dbout.add_field dbin.field(name).dup
          end
          schema_initialized = true
        end

        rainfall_data = dbin.fields\
            .select {|field| rainfall_field?(field.name) }\
            .map {|field| [extract_datetime(field.name), field.name] }
        dbin.each_record do |rec|
          next unless valid_record?(rec, additional)
          rainfall_data.each do |datetime, name|
            dbout.append {|r|
              r.datetime = datetime
              r.rainfall = rec[name]
              additional.each do |n|
                r[n] = rec[n]
              end
            }
          end
        end
      }
    end
  }
end

# ALL needed fields must contain non-space chars.
def valid_record?(record, needed_fields)
  needed_fields.map {|name| record.field(name) }\
      .all? {|f| not (f.string_field? and f.value.gsub(/ /, "").empty?) }
end

# Format of rainfall field  e.g. T039250030
RAINFALL_FIELD_RE = /\AT(\d\d)([\da-f])(\d\d)(\d\d)(\d0)\z/

def rainfall_field?(name)
  RAINFALL_FIELD_RE.match(name)
end

# rainfall field name -> datetime string
def extract_datetime(fieldname)
  m = RAINFALL_FIELD_RE.match(fieldname)
  year = m[1]; month = m[2].hex; date = m[3]
  hour = m[4]; minute = m[5]
  "20#{year}/#{month}/#{date} #{hour}:#{minute}:00"
end

main
