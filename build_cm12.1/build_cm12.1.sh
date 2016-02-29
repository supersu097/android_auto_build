#!/bin/bash
#===============================================================================
#          FILE: build_cm12.1.sh
#         USAGE: ./build_cm12.1.sh 
# 
#   DESCRIPTION: 
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: teddy.gan@antlauncher.com
#  ORGANIZATION: Ant Tech Corp.
#       CREATED: 11/21/2015 18:27
#===============================================================================

ORIGIN="\033[0m"  
YELLOW="\033[33m"
RED="\033[31m"
CPROMPT="\033[36m"

CODE_NAME=$1
BUILD_TYPE=$2
shself=`basename $0 .sh`

usage()
{
	cat <<-EOF
	USAGE:
	./build_*.sh CODE_NAME BUILD_TYPE
	./build_*.sh OPTION

	OPTION:
	-e|--envchange		: Change java env to match the requirement of current droid dev env
	-d|--dotabuild OLD_TARFILE NEW_TARFILE		: Build incremental(aka delta) android ota rom
	EOF
}

perror()                                                                         
{
	echo -e "${RED}${*}${ORIGIN}"
}

pright()
{
	echo -e "${CPROMPT}${*}${ORIGIN}"
}

palarm()
{
	echo -e "${YELLOW}${*}${ORIGIN}"
}

prompt()
{
	palarm "\n#===============================================================================\n"
	palarm "# Once you run this script of build_*.sh to build android tree "
	palarm "# successfully,a directory will be made one of user udb(means"
	palarm "# userdebug) and eng accordding to the [BUILDTYPE] you passed."
	palarm "# And as you can see,the file of out will not be a directory anymore,"
	palarm "# even that you may be asked to remove it! The OUT directory is"
	palarm "# just a symbolic link of out_[BUILDTYPE],you can use the command"
	palarm "# of 'ls -ld out(execute it in the root dir of droid source)'"
	palarm "# to watch out which it belongs to!"
	palarm "# All things above that I've done in order to decrease the time"
	palarm "# of building android tree when you change buildtype,but it will"
	palarm "# also increase the disk space usage at the same time!!!\n"
	palarm "#==============================================================================="
	pright "\nJust wait 10 seconds...\n"
}

build_ini_init()
{
	(cat <<-EOF) > $shself.ini
	### 以下字段应该被赋值为当前安卓工程源码所要求的JDK版本的相应目录的"绝对路径",
	##  注意：路径的最后不要有斜线‘/’ 
	JAVA_HOME_DIR =

	### 以下字段应该被赋值为一个文件夹的"绝对路径"，该文件夹下将会生成一个用机型codename为名字的文件夹，
	##  在该文件夹下又会分别生成三个名为user,userdebug,eng的文件夹，而每个文件夹下又会生成
	#   Delta_ota,Full_ota,Target_file三个文件夹,它们分别用来存放编译生成的差分包(增量升级包)，
	#   完整升级包和目标中间包。注意：路径的最后不要有斜线‘/’！
	ROM_STORE =

	### 以下字段应该被赋值为一个字符串，用于对生成的rom的zip文件进行重命名，
	##  例如一个名为AntRom-1.0-hammerhead-userdebug-20151029.1336.zip中的“AntRom”。
	OEM_BRAND_MOD =
	EOF
}

build_ini_init_check()
{
	if [ ! -f $shself.ini ];then
		build_ini_init
		pright "\n$shself.ini had inited."
		pright "You'd fill corresponding value behind the"
		pright "filed according to the comments above."
		exit 0
	fi
}


build_ini_value_check()
{
	build_ini_init_check
	T=`grep $1 $shself.ini | cut -d '=' -f 2`
	if [ -z $T ];then
		perror "\nThe value of the $1 do not exist," 
		perror "Pls check the $shself.ini!"
		exit 1
	fi
}
### Get build arguements...
android_build_env_set()
{
	local JPATH=/usr/bin
	local JAVA_BIN=(java javac)

	build_ini_value_check JAVA_HOME_DIR

	local JHOME_BIN=$T/bin

	### Check java env whether they match andorid build system
	if (java -version 2>&1 | grep 1.7)
		(java -version 2>&1 | grep -i openjdk)
		(javac -version 2>&1 | grep 1.7);then
		pright "\nJava dev env match droid build sys,do nothing..."

	else

		### Remove old java binary symbolic link then creat new in JPATH
		cat <<-EOF
		Note that:
		Remove old symbolic link need high privileges，
		u maybe asked for typing current 
		admin's passwd or not!
		EOF

		pright "\nRemove old java binary symbolic link then creat new..."

		for J in ${JAVA_BIN[@]}
		do
			if [ 1 -eq 1 ];then
				sudo rm -v $JPATH/${J} 2>/dev/null;
				sudo ln -sv $JHOME_BIN/${J} $JPATH
			fi
		done
	fi
}

### check whether there exists new version of Antlauncher
antlauncher_update()
{
	local REMOTE_DIR="datas"
	local HOST=""
	local ANT_USER="userftp"
	local PASSWD="userftp0916"
	local ANT_LOCAL_DIR=packages/apps/AntLauncher

	### antver.init check and creatt
	if [ -f ${ANT_LOCAL_DIR}/antver.init ];then
		pright "\nAntver.init file detected..."
		local LOCAL_VERSION=`tail -1 ${ANT_LOCAL_DIR}/antver.init`
	else
		echo  "AntLauncher version init file ,do not delete!\n1.0.0.apk" > \
		${ANT_LOCAL_DIR}/antver.init
		local LOCAL_VERSION=`tail -1 ${ANT_LOCAL_DIR}/antver.init`
	fi

	### Get remote version lib
	ftp -in >/dev/null <<-EOF
	open ${HOST}
	user ${ANT_USER} ${PASSWD}
	cd ${REMOTE_DIR}
	nlist *.apk /tmp/ant.tmp
	bye
	EOF
	local REMOTE_VERSION=`tail -1 /tmp/ant.tmp`

	### AntApp version check...
	pright "\nChecking AntLauncher version,Please wait..."
	if [ ${LOCAL_VERSION} = ${REMOTE_VERSION} ];then
		pright "\nAntApp version is equal to remote's..."
	else
		pright "\nAntLauncher has new version."
		pright "\nSyncing AntLauncher App start..."

		### Downloading AntLauncher start
		ftp -in >/dev/null <<-EOF
		open ${HOST}
		user ${ANT_USER} ${PASSWD}
		cd ${REMOTE_DIR}
		lcd ${ANT_LOCAL_DIR}
		binary
		get ${REMOTE_VERSION}
		bye
		EOF

		### Update AntLauncher version lib
		echo ${REMOTE_VERSION} >> ${ANT_LOCAL_DIR}/antver.init

		### rename apk name
		cd ${ANT_LOCAL_DIR}
		mv ${REMOTE_VERSION} AntLauncher.apk;cd -

		pright "\nSyncing AntLauncher App complete."
	fi
}

### Check buildtype,redirect out dir,Start build full ota rom
android_build_start()
{
	case $BUILD_TYPE in
		user|eng|userdebug)
			;;
		*)
			usage;perror "\nBuildType is incorrect,";\
			perror "it must be one of the user eng and userdebug,";\
			perror "pls check it!";exit 1
			;;
	esac

	android_build_env_set

	# Ck the vaule of ROM_STORE in build_*.sh
	build_ini_value_check ROM_STORE
	ROM_STORE=$T

	prompt
	sleep 10

	PRODUCT_OUT_PATH=out/target/product/${CODE_NAME}
	BUILD_PROP=${PRODUCT_OUT_PATH}/system/build.prop
	ANT_ROM_DESTINATION_BASE_PATH=$ROM_STORE/${CODE_NAME}/${BUILD_TYPE}

	final_target_move()
	{
		build_ini_value_check OEM_BRAND_MOD
		OEM_BRAND_MOD=$T
		
		### Ck dir struct
		dir_temp=(Delta_ota  Full_ota  Target_file)
		for f in ${dir_temp[@]};do
			if [ ! -d $ROM_STORE/$CODE_NAME/$BUILD_TYPE/$f ];then
				mkdir -p $ROM_STORE/$CODE_NAME/$BUILD_TYPE/$f
			fi
		done

		### Move full ota rom to destination and rename
		mv ${PRODUCT_OUT_PATH}/cm_${CODE_NAME}-ota-${BUILD_NUMBER}.zip \
			${ANT_ROM_DESTINATION_BASE_PATH}/\
			Full_ota/$OEM_BRAND_MOD-1.0-${CODE_NAME}-${BUILD_TYPE}-${ANT_ROM_VERSION}.zip

		### Move target file to destination and rename
		mv ${PRODUCT_OUT_PATH}/obj/PACKAGING/target_files_intermediates/\
			cm_${CODE_NAME}-target_files-${BUILD_NUMBER}.zip \
			${ANT_ROM_DESTINATION_BASE_PATH}/Target_file/\
			$OEM_BRAND_MOD-1.0-target_files-${CODE_NAME}-${BUILD_TYPE}-${ANT_ROM_VERSION}.zip

	}

	out_dir_ck()
	{
		### Soft link creat
		if [ -d out ];then
			### Check the file of out whether it's a symbolic link
			if [ -L out ];then
				### Check the long info of out file
				if ! ls -l out | grep $1;then
					rm out
					ln -s out_$1 out
				fi
			else
				pright "\nThe file of [out] is a directory."
				pright "And we could't decide whether it shoud be removed."
				echo -en "${YELLOW}Do you want to definitely remove it entirely(y/n)?${ORIGIN} "
				read -t 60 t
				case $t in
					y|Y)
						pright "Some files of out dir may belong to root user"
						pright "So u may need root privilege to remove them entirely..."
						sleep 3
						sudo rm -rf out
						;;
					n/N)
						pright "Do nothing!"
						exit 0
						;;
					*)
						exit 0
						;;
				esac
			fi
		else
			ln -s out_$1 out
		fi
	}

	out_buildtype_dir_ck()
	{
		### android out_buildtype_dir check
		if [ -d out_$1 ];then
			pright "\nOut_eng dir already exists..."
		else
			mkdir out_$1
		fi
	}

	android_real_build()
	{
		source build/envsetup.sh
		antlauncher_update
		pright "\nUpdate buildinfo..."
		touch build/tools/buildinfo.sh
		brunch cm_${CODE_NAME}-$BUILD_TYPE

		if [ $? -ne 0 ];then
			perror "Build rom failed,pls check it!"
		fi

		ANT_ROM_VERSION=`grep antos.update $BUILD_PROP | cut -d "=" -f 2`
		final_target_move
	}

	if [ ${BUILD_TYPE} = eng ];then
		pright "\nBuildtype is eng"
		out_buildtype_dir_ck eng
		out_dir_ck eng
		android_real_build
	elif [ ${BUILD_TYPE} = userdebug ];then
		out_buildtype_dir_ck udb
		out_dir_ck udb
		android_real_build
	else
		perror "\nDon't support user buildtype now!"
		exit 1
	fi
}

android_dota_build()
{
	### Check args number
	if [ $# -ne 2 ];then
		perror "\nThere must be 2 args behind the arg of '-d'"
		exit 1
	fi

	build_ini_value_check ROM_STORE
	ROM_STORE=$T

	build_ini_value_check OEM_BRAND_MOD
	OEM_BRAND_MOD=$T

	### Rename args function called 
	OLD_TARFILE_NAME=$1
	NEW_TARFILE_NAME=$2

	### Detect whether there are target-files
	if ! echo $OLD_TARFILE_NAME |grep target_files ||\
	 ! echo $NEW_TARFILE_NAME |grep target_files;then
		perror "\nAt least one of zip files you passed is"
		perror "not target-file that we need!"
		exit 1
	fi 

	### Check both codename and buildtype whether there are same
	CODE_NAME_OLD=`echo $OLD_TARFILE_NAME | cut -d "-" -f 4`
	CODE_NAME_NEW=`echo $NEW_TARFILE_NAME | cut -d "-" -f 4`
	BUILD_TYPE_OLD=`echo $OLD_TARFILE_NAME | cut -d "-" -f 5`
	BUILD_TYPE_NEW=`echo $NEW_TARFILE_NAME | cut -d "-" -f 5`
	if [ $BUILD_TYPE_OLD != $BUILD_TYPE_NEW -o\
	 $CODE_NAME_OLD != $CODE_NAME_NEW ];then
		perror "\nAt least one pair of target-file's"
		perror "codename and buildtype is not same!"
		exit 1
	fi

	### Check target-file whether there exist in define path
	OLD_TARFILE_PATH=`find $ROM_STORE/$CODE_NAME_OLD -name $OLD_TARFILE_NAME`
	NEW_TARFILE_PATH=`find $ROM_STORE/$CODE_NAME_OLD -name $NEW_TARFILE_NAME`
	if [ -z $OLD_TARFILE_PATH -o -z $NEW_TARFILE_PATH ];then
		perror "At least one of target_files you passed don't exist!"
		exit 1
	fi

	### Start to build delta ota rom then upload
	CYEAR=`date "+%Y"`
	DELTA_OTA_ROM_NAME=$OEM_BRAND_MOD-1.0-${CODE_NAME_OLD}-${BUILD_TYPE_OLD}-\
	`basename $OLD_TARFILE_PATH .zip | sed "s/^.*-$CYEAR//g"`_\
	`basename $NEW_TARFILE_PATH .zip | sed "s/^.*-$CYEAR//g" `.zip

	./build/tools/releasetools/ota_from_target_files \
	-k build/target/product/security/testkey -i \
	$OLD_TARFILE_PATH $NEW_TARFILE_PATH ${DELTA_OTA_ROM_NAME}

	### Ck dota build whether it works fine
	if [ $? -ne 0 ];then
		perror "\nDota build may not succeed,pls check it"
		exit 1
	else
		pright "\nDota build succeed,"
		pright "then it'll be uploaded to the FTP server!"
	fi

	if [ ! -d $ROM_STORE/$CODE_NAME_OLD/$BUILD_TYPE_OLD/Delta_ota ];then
		perror "\nU may not use the sh script of $shself.sh"
		perror "to build rom,dir hierarchy is not what we need!"
		exit 1
	fi

	### Move delta rom,both old and new are all OK!
	mv ${DELTA_OTA_ROM_NAME} \
	$ROM_STORE/$CODE_NAME_OLD/$BUILD_TYPE_OLD/Delta_ota

	### Ck mv and rename dota whether it succeed
	if [ $? -ne 0 ];then
		perror "Move and rename dota rom zip file fail,"
		perror "pls check corresponding file and dir!"
		exit 1
	fi

	### Upload delta ota rom to ftp server
	echo -e "\nStart to upload delta ota rom to ftp server..."
	REMOTE_DIR="pack/ANT/${CODE_NAME}"
	HOST=""
	ANT_USER="userftp"
	PASSWD="userftpant"

	ftp -in >/dev/null <<-EOF
	open ${HOST}
	user ${ANT_USER} ${PASSWD}
	cd ${REMOTE_DIR}
	lcd $ROM_STORE/$CODE_NAME_OLD/$BUILD_TYPE_OLD/Delta_ota
	binary
	put ${DELTA_OTA_ROM_NAME}
	bye
	EOF

	pright "\nDelta rom upload ended"

}

### Script arguements passed analysis...

if [ $# -eq 0 -o $# -gt 3 ];then
	usage;exit 1
fi

case $1 in
	-h|--help)
		usage;exit 0
		;;
	-e|--envchange)
		android_build_env_set
		;;
	-d|--dotabuild)
		android_dota_build $2 $3
		;;
	*)
		;;
esac

### Real build start...
android_build_start
