=begin
		dbf.rb
		
		05-11-21
=end

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#		DBFheader
#		�w�b�_�擱��
#
# �C���^�[�t�F�C�X
#		version, date1, date2, date3, numrec, headerbytes, recordbytes, reserve
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class DBFheader
	def initialize
		@version = nil			# �o�[�W�����Ȃ�
		@date1 = nil				# �ŏI�X�V��(�N�j
		@date2 = nil				# �ŏI�X�V��(���j
		@date3 = nil				# �ŏI�X�V��(���j
		@numrec = nil				# ���R�[�h��
		@headerbytes = nil	# �w�b�_�̃o�C�g��
		@recordbytes = nil	# ���R�[�h�̃o�C�g��
		@reserve = nil			# �\��̈�Ȃ�
	end
	attr_accessor :version, :date1, :date2, :date3, :numrec, :headerbytes, :recordbytes, :reserve
end

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#		DBFfield
#		�t�B�[���h�v�f
#
# �C���^�[�t�F�C�X
#		fieldname, fieldtype, fieldsize, decimal, value
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class DBFfield
	def initialize
		@fieldname = ""			#�t�B�[���h��
		@fieldtype = ""			#�t�B�[���h�^
		@fieldsize = 0			#�t�B�[���h��
		@decimal = 0				#�t�B�[���h��������
		@value = nil				#�t�B�[���h�l
	end
	attr_accessor :fieldname, :fieldtype, :fieldsize, :decimal, :value
end

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#		DBFfields
#		�t�B�[���h�L�q�z��
#
# �C���^�[�t�F�C�X
#		add, fieldname, item, numfields
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class DBFfields
	def initialize
		@fieldarray = []		#�t�B�[���h�v�f�̔z��
		@fieldhash = {}			#�t�B�[���h���ŃA�N�Z�X���邽�߂̃n�b�V���z��
	end

#-----------------------------------------------------------------------
#		add
#
#		�t�B�[���h��`�������ɁA�t�B�[���h�z��Ƀt�B�[���h�v�f��ǉ�����
#
# ����
#		fname�F�t�B�[���h��
#		ftype�F�^
#		fsize�F�t�B�[���h��
#		dec�F��������
# �߂�l
#		�Ȃ�
#-----------------------------------------------------------------------
	def add(fname, ftype, fsize, dec)
		@field = DBFfield.new
		@field.fieldname = fname
		@field.fieldtype = ftype
		@field.fieldsize = fsize
		@field.decimal = dec

		@fieldarray.push(@field)
		@fieldhash[@field.fieldname] = @fieldarray.size - 1		#�t�B�[���h���ɑΉ�����t�B�[���h�ԍ����擾����
	end

#-----------------------------------------------------------------------
#		fieldname
#
# �T�v
#		�t�B�[���h�ԍ��������ɁA�t�B�[���h����Ԃ�
#
# ����
#		num�F�t�B�[���h�ԍ�
# �߂�l
#		�t�B�[���h��
#-----------------------------------------------------------------------
	def fieldname(num)
		@fieldarray[num].fieldname
	end

#-----------------------------------------------------------------------
#		item
#		�t�B�[���h�ւ̃A�N�Z�X
#
# �T�v
#		�t�B�[���h���������ɁA�t�B�[���h�L�q�z��̗v�f��Ԃ�
#
# ����
#		�t�B�[���h��
# �߂�l
#		�t�B�[���h�v�f
#-----------------------------------------------------------------------
	def item(fname)
		@fieldarray[@fieldhash[fname]]
	end

#-----------------------------------------------------------------------
#		numfields
#
# �T�v
#		�t�B�[���h�L�q�z��̗v�f����Ԃ�
#
# ����
#		�Ȃ�
# �߂�l
#		�t�B�[���h��
#-----------------------------------------------------------------------
	def numfields
		@fieldarray.size
	end
end		# class DBFfields

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#		DBFrecordset
#
# �T�v
#		�f�[�^�x�[�X�t�@�C���́A�ȉ��̂R�̕�������Ȃ�
#		�P�@�w�b�_�擱��
#		�Q�@�t�B�[���h�L�q��
#		�R�@�f�[�^���R�[�h��
#
# �C���^�[�t�F�C�X
#		addfield, dbfopen, close, eof, movefirst, movenext, addnew, update
#		numfields, fieldname, fieldspec, fields
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class DBFrecordset
	def initialize
		@hdlead = DBFheader.new		#�w�b�_�擱��
		@fields = DBFfields.new		#�t�B�[���h�L�q�z��

		@dbfeof = FALSE			#EOF
		@dbfbof = FALSE			#BOF
		@headerset = FALSE	# �t�@�C���Ƀw�b�_�����������܂�Ă��邩
		@currentrecno = -1	# 0����n�܂郌�R�[�h�ԍ�
		@numrecords = 0			# 1����n�܂郌�R�[�h��
		@headerlen = 0			# �w�b�_�� 
		@recordlen = 0			# ���R�[�h��
	end

#-----------------------------------------------------------------------
#		addfield
#
# ����
#		fname�F�t�B�[���h��
#		ftype�F�^
#		fsize�F�t�B�[���h��
#		dec�F��������
# �߂�l
#		�Ȃ�
#-----------------------------------------------------------------------
	def addfield(fname, ftype, fsize, dec)
		@fields.add(fname, ftype, fsize, dec)
	end

#-----------------------------------------------------------------------
#		dbfopen
#
# �T�v
#		�Ǎ��݃��[�h�ł́A�w�b�_��ǂݍ���Ńt�B�[���h�z��ɃZ�b�g����
#		�����݃��[�h�ł́A�I�[�v�����邾���ŉ������Ȃ�
#
# ����
#		filename�F�t�@�C����
#		openmode�F�I�[�v�����[�h "r"=�Ǎ��݁Ac=�V�K�쐬
# �߂�l
#		�Ȃ�
#-----------------------------------------------------------------------
	def dbfopen(filename, openmode)
		if openmode != "r" and openmode != "c" then
			p "�I�v�V�����̃I�[�v�����[�h [" + openmode + "] ���s���ł�"
			exit
		end

		@openmode = openmode
		# �ǂݍ��݃��[�h
		if openmode == "r" then
			@fp = open(filename, "rb+")
			if @fp != nil then
				# �idbf�w�b�_��ǂݍ���ł��A���܂̂Ƃ���g���߂ǂ͂Ȃ����j
				#1�@�w�b�_�擱��
				@hdlead.version = @fp.read(1)
				@hdlead.date1 = @fp.read(1)
				@hdlead.date2 = @fp.read(1)
				@hdlead.date3 = @fp.read(1)
				@hdlead.numrec = @fp.read(4)
				@hdlead.headerbytes = @fp.read(2)
				@hdlead.recordbytes = @fp.read(2)
				@hdlead.reserve = @fp.read(20)
				
				@numrecords = @hdlead.numrec.unpack("l").pop 		# - 1
				@headerlen = @hdlead.headerbytes.unpack("s").pop
				@recordlen = @hdlead.recordbytes.unpack("s").pop

				#2�@�t�B�[���h�L�q��
				numfields = (@hdlead.headerbytes.unpack("s").pop - 1) / 32 - 1
				count = 0
				while count < numfields do
					hdldfieldname = @fp.read(11)	# �t�B�[���h�̌��ɋl�܂��Ă���\000���J�b�g����
					hdldfieldtype = @fp.read(1)
					hdldreserve1 = @fp.read(4)
					hdldfieldsize = @fp.read(1)
					hdlddecimal = @fp.read(1)
					hdldreserve2 = @fp.read(14)
					
					@fields.add(hdldfieldname.scan(/^[^\000]+/).pop, hdldfieldtype, hdldfieldsize.unpack("C").pop, hdlddecimal.unpack("C").pop)
					
					count += 1
				end		#while count < numfields do
				@headerset = TRUE		# �w�b�_�����m�F����
			else
				p "infile open fail"
			end

		# �V�K�쐬���[�h
		else
			@fp = open(filename, "wb+")
		end
	end		#def dbfopen(filename, openmode)

#-----------------------------------------------------------------------
#		eof
#-----------------------------------------------------------------------
	def eof
		@dbfeof
	end

#-----------------------------------------------------------------------
#		close
#		�V�K�쐬���[�h�̏ꍇ�A�w�b�_��������
#-----------------------------------------------------------------------
	def close
		if @openmode == "c" then
			putheader
			# �t�@�C���̏I�[�}�[�N�iChr(26)�A&H1A�A&O32�j����������
			@fp.seek(0 + @headerlen + @recordlen * @numrecords, File::SEEK_SET)
			@fp.write("\x1a")
		end
		
		if @fp != nil then
			@fp.close
		end
	end

#-----------------------------------------------------------------------
#		movefirst
#		�|�C���^���ŏ��ɃZ�b�g���ĂP���R�[�h�Ǎ���
#
#	�t�@�C���̓ǂݏ����ʒu�́A���R�[�h�ԍ������Ɏw�肷��
#	�t�@�C���I�[�ɃR�[�h(&H1A �H)�����邽�߁A���R�[�h����m���ĂȂ���eof�𑨂����Ȃ�
#-----------------------------------------------------------------------
	def movefirst
		if @headerset == FALSE then
			return FALSE
		end
		
		@currentrecno = 0
		moverecord(@currentrecno)
		readrecord
	end

#-----------------------------------------------------------------------
#		movenext
#		���R�[�h�|�C���^�P�i�߁A���R�[�h��Ǎ���
#-----------------------------------------------------------------------
	def movenext
		@currentrecno += 1
		moverecord(@currentrecno)
		if @currentrecno >= @numrecords then
			@currentrecno = @numrecords - 1
		else
			readrecord
		end
	end

#-----------------------------------------------------------------------
#		addnew
#		�ǂݏ����|�C���^���Ō�̃��R�[�h�̌��ɓ�����
#		��̃t�@�C���ɑ΂���ŏ��̃��R�[�h�ǉ��̏ꍇ�A�w�b�_������������ł���ǂݏ����|�C���^���Z�b�g����
#-----------------------------------------------------------------------
	def addnew
		if @headerset == FALSE then
			putheader
		end
		@currentrecno = @numrecords
		@fp.seek(0 + @headerlen + @recordlen * @currentrecno, File::SEEK_SET)

		count = 0
		while count < (@fields.numfields) do
			typechar = @fields.item(@fields.fieldname(count)).fieldtype
			if typechar == "N" or typechar == "F" then
				@fields.item(@fields.fieldname(count)).value = 0.0
			elsif typechar == "C" then
				@fields.item(@fields.fieldname(count)).value = ""
			else
				p "illegal type"
			end
			count += 1
		end
	end		# while count < (@fields.numfields) do

#-----------------------------------------------------------------------
#		update
#-----------------------------------------------------------------------
	def update
		writerecord
		
		if @currentrecno == @numrecords then		#   + 1
			@numrecords += 1
		end
	end

#-----------------------------------------------------------------------
#		numfields
#-----------------------------------------------------------------------
	def numfields
		@fields.numfields
	end

#-----------------------------------------------------------------------
#		fieldname
#-----------------------------------------------------------------------
	def fieldname(num)
		@fields.fieldname(num)
	end

#-----------------------------------------------------------------------
#		fieldspec
#		�t�B�[���h�L�q�z��ւ̃C���^�[�t�F�C�X
#		����킵�����A����fields�łȂ��A�����炪@fields�I�u�W�F�N�g��Ԃ�
#		����������A�g��Ȃ�
#-----------------------------------------------------------------------
	def fieldspec
		@fields
	end

#-----------------------------------------------------------------------
#		fields
#		�t�B�[���h�v�f�ւ̃C���^�[�t�F�C�X
#		����킵�����A@field�I�u�W�F�N�g��Ԃ��̂ł͂Ȃ��Aitem��Ԃ�
#-----------------------------------------------------------------------
	def fields(fname)
		@fields.item(fname)
	end

#-----------------------------------------------------------------------
#		putheader
#-----------------------------------------------------------------------
	def putheader
		@fp.seek(0, File::SEEK_SET)

		#1�@�w�b�_�擱��
		@fp.write("\003")																			# �o�[�W�����Ȃ�
		@fp.write([Time.now.strftime("%y").to_i].pack("c"))		# �ŏI�X�V��(�N�j
		@fp.write([Time.now.strftime("%m").to_i].pack("c"))		# �ŏI�X�V��(���j
		@fp.write([Time.now.strftime("%d").to_i].pack("c"))		# �ŏI�X�V��(���j
		@fp.write([@numrecords].pack("l"))										# ���R�[�h��
		@headerlen = ((@fields.numfields + 1) * 32 + 1)				# �w�b�_�̃o�C�g�� �w�b�_�擱��(32�o�C�g)�{���t�B�[���h�L�q��(32�o�C�g) �{�P  �w�b�_�̏I����1�o�C�g�t��
		@fp.write([@headerlen].pack("s"))	

		count = 0
		@recordlen = 1
		while count < (@fields.numfields) do
			@recordlen += @fields.item(@fields.fieldname(count)).fieldsize	
			count += 1
		end
		@fp.write([@recordlen].pack("s"))					# ���R�[�h�̃o�C�g�� ��((�t�B�[���h��)+1) ���R�[�h�̐擪�ɍ폜�t�B�[���h���t��
		@fp.write("\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000")		# �\��̈�Ȃ� 20�o�C�g�o��

		#2�@�t�B�[���h�L�q��
		count = 0
		while count < (@fields.numfields) do
			#�t�B�[���h��   �iDBF �t�@�C���̒�`�ł�11�o�C�g)
			fieldnamelen = 0
			fieldnamearr = @fields.fieldname(count).split(//)
			while fieldnamelen < 11 do
				if fieldnamearr.size > 0 then
					@fp.write(fieldnamearr.shift)
				else
					@fp.write("\000")
				end
				fieldnamelen += 1
			end

			@fp.write(@fields.item(@fields.fieldname(count)).fieldtype)			# �t�B�[���h�^   N,F:���l�^�AC:�����^
			@fp.write("\000\000\000\000")																		# �\��̈�i4�o�C�g�j
			@fp.write([@fields.item(@fields.fieldname(count)).fieldsize.to_i].pack("C"))	# �t�B�[���h��
			@fp.write([@fields.item(@fields.fieldname(count)).decimal.to_i].pack("C"))		# �������̒���
			@fp.write("\000\000\000\000\000\000\000\000\000\000\000\000\000\000")					# �\��̈�Ȃǁi14�o�C�g�j
			
			count += 1
		end		# while count < (@fields.numfields) do
		
		#2�@�w�b�_���i�t�B�[���h�L�q���j�̏I���}�[�N�i&H0D�j
		@fp.write("\x0d")
		@headerset = TRUE		# �w�b�_������������
	end

#-----------------------------------------------------------------------
#		writerecord
#-----------------------------------------------------------------------
	def writerecord
		# 1�o�C�g�󔒂��o�́idbf�t�@�C���d�l�̍폜�}�[�N�j
		@fp.write(" ")
		
		count = 0
		while count < (@fields.numfields) do
			typechar = @fields.item(@fields.fieldname(count)).fieldtype
			if typechar == "N" or typechar == "F" then
				# ��F@fp.printf("%8.3f", value)
				@fp.printf("%" + @fields.item(@fields.fieldname(count)).fieldsize.to_s + "." + @fields.item(@fields.fieldname(count)).decimal.to_s + "f",  @fields.item(@fields.fieldname(count)).value)
			elsif typechar == "C" then
				# ��F@fp.printf("%-8s", value)
				@fp.printf("%-" + @fields.item(@fields.fieldname(count)).fieldsize.to_s + "s",  @fields.item(@fields.fieldname(count)).value)
			else
				p "illegal type"
			end
			count += 1
		end		# while count < (@fields.numfields) do
	end

#-----------------------------------------------------------------------
#		readrecord
#-----------------------------------------------------------------------
	def readrecord
		# �P�o�C�g�ǂݎ̂Ă�idbf�t�@�C���d�l�̍폜�}�[�N�j
		@fp.read(1)
		
		count = 0
		while count < (@fields.numfields) do
			typechar = @fields.item(@fields.fieldname(count)).fieldtype
			if typechar == "N" or  typechar == "F" then
				@fields.item(@fields.fieldname(count)).value = @fp.read(@fields.item(@fields.fieldname(count)).fieldsize).to_f
			elsif typechar == "C" then
				@fields.item(@fields.fieldname(count)).value = @fp.read(@fields.item(@fields.fieldname(count)).fieldsize)
			else
				p "illegal type"
			end
			count += 1
		end		# while count < (@fields.numfields) do
	end

#-----------------------------------------------------------------------
#		moverecord
#		�|�C���^�������̃��R�[�h�ԍ��ɃZ�b�g����
#
# ����
#		recno�F���R�[�h�ԍ�
# �߂�l
#		�Ȃ�
#-----------------------------------------------------------------------
	def moverecord(recno)
		if recno >= @numrecords then
			@dbfeof = TRUE
		elsif recno < 0 then
			@dbfbof = TRUE
		else
			@dbfeof = FALSE
			@dbfbof = FALSE
			# �ǂݏ����̊J�n�ʒu�ɃZ�b�g�@�w�b�_���̍Ō��1�o�C�g�̃R�[�h(&H0D)������
			# �o�C�g�ʒu�͂O����n�܂�B���R�[�h�ԍ��͂O����n�܂�B
			@fp.seek(0 + @headerlen + @recordlen * recno, File::SEEK_SET)
		end
	end

#-----------------------------------------------------------------------
#		�Ăяo������
#-----------------------------------------------------------------------
	protected :putheader, :writerecord, :readrecord, :moverecord

end		# class DBFrecordset
