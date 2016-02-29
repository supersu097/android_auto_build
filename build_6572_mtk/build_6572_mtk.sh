#!/bin/bash
#===============================================================================
#          FILE: build_6572_mtk.sh
#         USAGE: ./build_6572_mtk.sh 
# 
#   DESCRIPTION: 
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: teddy.gan@antlauncher.com
#  ORGANIZATION: Ant Tech Corp.
#       CREATED: 11/21/2015 18:27
#===============================================================================

### MEMO:
# The value of BUILD_TYPE come from current script itself args passed
# The value of PRODUCT_NAME come from build_*.ini,it inited in function of android_build_start()
# The value of BUILD_ACTION come from the function of android_build_start's args passed,it is defined as a loacal variable! 

#set some variable
ORIGIN="\033[0m"
YELLOW="\033[33m"
RED="\033[31m"
CPROMPT="\033[36m"

BUILD_TYPE=$1
shself=`basename $0 .sh`

usage()
{
	cat <<-EOF
	USAGE:
	./build_*.sh BUILD_TYPE
	./build_*.sh OPTION

	OPTION:
	-e|--envchange		: Change java env to match the requirement of current droid dev env
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
	echo
	palarm "#===============================================================================\n"
	palarm "# Once you run this script of build_*.sh to build android tree "
	palarm "# successfully,a directory will be made one of user udb(means"
	palarm "# userdebug) and eng accordding to the [BUILDTYPE] you passed."
	palarm "# And as you can see,the file of out will not be a directory anymore,"
	palarm "# even that you may be asked to remove it! The OUT file is"
	palarm "# just a symbolic link of out_[BUILDTYPE],you can use the command"
	palarm "# of 'ls -ld out(execute it in the root dir of android source)'"
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
	### 以下字段应该被赋值为当前安卓工程源码所要求的JDK版本的相应目录的"绝对路径",注意：路径的最后不要有斜线‘/’ 
	JAVA_HOME_DIR =

	### 以下字段应该被赋值为当前项目的codename,例如hexing72_cwet_kk(对于MTK平台)
	PRODUCT_NAME =
	EOF
}

android_build_env_set()
{
	local JPATH=/usr/bin
	local JAVA_BIN=(java javac javap javadoc)

	if [ -f $shself.ini ];then
		pright "$shself.ini detected!"
	else
		build_ini_init
		pright "$shself.ini had inited."
		pright "You'd fill corresponding value behind the filed according to the comments above."
		exit 0
	fi

	local JHOME=`grep JAVA_HOME_DIR $shself.ini | cut -d '=' -f 2`

	if [ -z $JHOME ];then
		perror "\nThe value of the JAVA_HOME_DIR do not exist," 
		perror "Pls check the $shself.ini!"
		exit 1
	fi

	local JHOME_BIN=$JHOME/bin
	### Check java env whether they match andorid build system
	if (java -version 2>&1 | grep 1.6)
		(java -version 2>&1 | grep -i HotSpot)
		(javac -version 2>&1 | grep 1.6);then
		pright "\nJava dev env match droid build sys,do nothing..."

	else

		### Remove old java binary symbolic link then creat new in JPATH
		cat <<-EOF
		Note that:
		Remove origin symbolic link need root privilege，
		u maybe asked for typing current 
		admin's passwd or not!
		EOF

		pright "\nRemove origin java binary symbolic link then creat new..."

		for i in ${JAVA_BIN[@]}
		do
			if [ 1 -eq 1 ];then
				sudo rm -v $JPATH/$i 2>/dev/null
				sudo ln -sv $JHOME_BIN/$i $JPATH
			fi
		done
	fi
}


android_build_start()
{
	
	case $BUILD_TYPE in
		user|eng|userdebug)
			;;
		*)
			usage;perror "\nBuildType is incorrect,pls check it!";exit 1
			;;
	esac

	android_build_env_set

	local BUILD_ACTION=$1
	PRODUCT_NAME=`grep PRODUCT_NAME $shself.ini | cut -d '=' -f 2`

	if [ -z $PRODUCT_NAME ];then
		perror "\nThe value of the PRODUCT_NAME do not exist,"
		perror "Pls check the $shself.ini"
		exit 1
	fi
	prompt
	sleep 10

	out_dir_ck()
	{
		### Soft link creat
		if [ -d out ];then

			### Check the file of out whether it's a symbolic link
			if [ -L out ];then

				### Check the long info of out file,
				### if the out file long info indicate that it belong to the out_$1 ,we do not rm it.
				if ! ls -l out | grep $1;then
					rm out
					ln -s out_$1 out
				fi

			else
				pright "The file of [out] is a directory."
				pright "And we could't decide whether it shoud be removed."
				echo -en "${YELLOW}Do you want to definitely remove it entirely(y/n)?${ORIGIN} "
				read -t 60 t
				case $t in
					y|Y)
						pright "Some files of out dir may belong to root user"
						pright "So u may need root privilege to remove them entirely..."
						sleep 5;sudo rm -rf out
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
			pright "Out_$1 dir already exists..."
		else
			mkdir out_$1
		fi
	}

	android_real_build()
	{
		pright "\nUpdate buildinfo..."
		pright "Start to build android tree,wait a few minutes..."
		touch build/tools/buildinfo.sh
		sudo ./mk -o=TARGET_BUILD_VARIANT=$BUILD_TYPE $PRODUCT_NAME $BUILD_ACTION
	}

	if [ ${BUILD_TYPE} = eng ];then
		pright "Buildtype is eng..."

		out_buildtype_dir_ck eng
		out_dir_ck eng
		android_real_build
	elif [ $BUILD_TYPE = userdebug ];then
		pright "Buildtype is userdebug..."

		out_buildtype_dir_ck udb
		out_dir_ck udb
		android_real_build

	else
		pright "Buildtype is user..."

		out_buildtype_dir_ck user
		out_dir_ck user
		android_real_build

	fi

}

### Script arguements passed analysis...
if [ $# -ne 1 ];then
	usage;exit 1
fi

case $1 in
	-h|--help)
		usage
		;;
	-e|--envchange)                                                              
		android_build_env_set
		;;
	*)
		;;
esac

### Real build start...
android_build_start remake

### Kernel changing...
if [ $? -eq 0 ];then
	./mksysimg.pl $BUILD_TYPE
else
	perror "\nmksysimg.pl do not run!"
	perror "Last process may not be succeed,pls check it!"
	exit 1
fi

### System.img repackage...
if [ $? -eq 0 ];then
	sudo mkdir out/target/product/$PRODUCT_NAME/system/bin/su
	sudo mkdir out/target/product/$PRODUCT_NAME/system/xbin/su
	android_build_start snod
else
	perror "\nandroid_build_start snod do not run!"
	perror "Last process may not be succeed,pls check it!"
	exit 1
fi