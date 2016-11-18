#! ruby -Ks
=begin
			dbfrecomb ver. 0.2
					05-11-21

			����dbf�t�@�C������A�Q�̃f�t�H���g�t�B�[���h(�����ƉJ��)�̑g�𔲂��o���Ďw�肵���t�B�[���h�������A���������R�[�h�Ƃ���dbf�t�@�C�����o�͂���
			�o�̓t�B�[���h�́A���̓��X�g�̐擪�t�@�C���̓����t�B�[���h�̒�`�Ƃ���B
			�����^�t�B�[���h���o�͎w�肷��ƁA���̂����ꂩ�P�ł��l�̂Ȃ����R�[�h�ɑ΂��ẮA���R�[�h���o�͂��Ȃ�
			���͂́A�R�}���h���C���Ŏw�肵�����X�g�t�@�C�������ɓǍ��ށB
			�o�͂́A�R�}���h���C���Ŏw�肵���o�̓t�@�C���ɑ����ď������ށB
			
=end

	require "dbf.rb"

	infile = ""
	outfile = ""
	refrain = 0.0

	if ARGV[0] == "-h" then
		p "dbfrecomb ver. 0.2"
		p "dbfrecomb [-opt] listfile outfile [reffield ...]"
		p "       opt:h         help"
		p "       reffield      reference field name"
		p ""
		p "(ex.) dbfrecomb listfile.txt outdata.dbf pntid name area"
		p ""
		p "listfile format:"
		p "dbffile1.dbf"
		p "dbffile2.dbf"
		p "  ..."

		exit
	end

	reffield = []
	reffieldnum = 0
	if ARGV.size >= 2 then
		listfile = ARGV[0]
		outfile = ARGV[1]
		count = 0
		while count < ARGV.size - 2
			reffield[count] = ARGV[count + 2]
			count += 1
		end
		

		reffieldnum = count		# �o�̓t�B�[���h��(�w��t�B�[���h�̂�)
	else
		p "�������s���ł�"
		p "dbfrecomb [-opt] listfile outfile [reffield ...]"
		p "       opt:h         help"
		p "       reffield      reference field name"
		p ""
		p "(ex.) dbfrecomb listfile.txt outdata.dbf pntid name area"
		
		exit
	end

	# ���̓��X�g�̎擾
	filelist = []
	count = 0
	fplist = open(listfile, "r")
	while not fplist.eof
		filelist[count] = fplist.gets.chomp
		count += 1
	end
	infilenum = count
	fplist.close

	datefield = "datetime"
	rainfallfield = "rainfall"

	dbfout = DBFrecordset.new
	dbfout.dbfopen(outfile, "c")

	# �o�̓t�B�[���h�̐����i����t�B�[���h�̂݁j
	dbfout.addfield(datefield, "C", 20, 0)
	dbfout.addfield(rainfallfield, "N", 10, 4)

	listcount = 0
	while listcount < infilenum
		dbfin = DBFrecordset.new		# �t�@�C�����ƂɃI�u�W�F�N�g�𐶐�����
		dbfin.dbfopen(filelist[listcount], "r")
		
p "input file:" + filelist[listcount]

		numfields = dbfin.numfields
		datetime = []
		outfield = []

		# �ŏ��̃t�@�C�������̏���
		# �o�̓t�B�[���h�̐����i�R�}���h���C���Ŏw�肵���t�B�[���h��ǉ��j
		if listcount == 0 then
			fieldcount = 0
			while fieldcount < numfields
				fieldname = dbfin.fieldname(fieldcount)
				count = 0
				while count < reffieldnum
					if fieldname.downcase == (reffield[count]).downcase then
						reffield[count] = fieldname		# �啶���������̈Ⴂ�ɂ�����炸�󂯕t����
						dbfout.addfield(fieldname, dbfin.fields(fieldname).fieldtype, \
													dbfin.fields(fieldname).fieldsize, dbfin.fields(fieldname).decimal)
					end
					count += 1
				end		# while count < reffieldnum
				fieldcount += 1
			end		# while fieldcount < numfields
		end		# if listcount == 0 then

		# ���̓t�@�C���̃t�B�[���h���Ƃ̏���
		filecomplete = 0
		outfieldcount = 0
		fieldcount = 0
		while fieldcount < numfields
			fieldname = dbfin.fieldname(fieldcount)
			
			# �J�ʃt�B�[���h�ł���΁A�����̌`���ɕϊ����Ĕz��Ɏ擾
			# �J�ʃt�B�[���h�̔��ʂ́A"T"�ł͂��܂�A�P�O�o�C�g�ŁA�Ōオ"0"�ł��邱�ƂƂ���B
			if fieldname[0, 1] == "T" and fieldname.size == 10 and fieldname[-1, 1] == "0" then		# T039250030
				outfield[outfieldcount] = fieldname
				datetime[outfieldcount] = "20" + fieldname[1, 2] + "/" \
																	+ sprintf("%02d", fieldname[3, 1].hex) + "/" \
																	+ fieldname[4, 2] + " " \
																	+ fieldname[6, 2] + ":" + fieldname[8, 2] + ":00"
				outfieldcount += 1
			end

			# �R�}���h���C���Ŏw�肵���t�B�[���h�����̓t�@�C���ɂ��邩���`�F�b�N
			count = 0
			while count < reffieldnum
				if fieldname  == (reffield[count])  then
					filecomplete += 1
				end
				count += 1
			end		# while count < reffieldnum
			fieldcount += 1
		end		#  while fieldcount < numfield

		# ���ׂẴt�B�[���h�����ăR�}���h���C���Ŏw�肵���t�B�[���h���Ȃ���΁A������
		if filecomplete != reffieldnum then
			p "�w�肵���t�B�[���h�� " + filelist[listcount] + " �̃e�[�u���ɂ���܂���"
			
			exit
		end

		# �o�̓t�@�C���̐���
		dbfin.movefirst
		while not dbfin.eof
			# ���͂������R�[�h���o�͂��邩���`�F�b�N
			# ���ׂĂ̕����^�̎w��t�B�[���h�ɋ󔒈ȊO�̒l�����邩�Ŕ��肷��
			count = 0
			validcount = 0
			refccount = 0
			while count < reffieldnum
				if dbfin.fields(reffield[count]).fieldtype == "C" then
					refccount += 1
					if dbfin.fields(reffield[count]).value.gsub(" ", "") != "" then
						validcount += 1
					end
				end
				count += 1
			end		# while count < reffieldnum

			# �����^�̎w��t�B�[���h�̂��ׂĂɋ󔒈ȊO�̒l�̂���ꍇ�Ƀ��R�[�h���o�͂���
			if validcount == refccount then
				count = 0
				while count < outfieldcount
					dbfout.addnew

					dbfout.fields(datefield).value = datetime[count]
					dbfout.fields(rainfallfield).value = dbfin.fields(outfield[count]).value
					refcount = 0
					while refcount < reffieldnum
						dbfout.fields(reffield[refcount]).value = dbfin.fields(reffield[refcount]).value
						refcount += 1
					end		# while refcount < reffieldnum

					dbfout.update
					count += 1
				end		# while count < outfieldcount
			end		# if count == reffieldnum then
			dbfin.movenext
		end		# while not dbfin.eof
		
		dbfin.close
		listcount += 1
	end		#  listcount < infilenum
	
	dbfout.close
