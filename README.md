## android_auto_build
init some action before real android rom build ,  
then auto generate Incremental ota rom  

```
USAGE:
./build_*.sh CODE_NAME BUILD_TYPE
./build_*.sh OPTION

OPTION:
-e|--envchange		: Change java env to match the requirement of current droid dev env
-d|--dotabuild OLD_TARFILE NEW_TARFILE		: Build incremental(aka delta) android ota rom
```

### Notice:
>Once you run this script of build_*.sh to build android tree  
successfully,a directory will be made one of user udb(means  
userdebug) and eng accordding to the [BUILDTYPE] you passed.  
And as you can see,the file of out will not be a directory anymore,  
even that you may be asked to remove it! The OUT directory is  
just a symbolic link of out_[BUILDTYPE],you can use the command  
of 'ls -ld out(execute it in the root dir of droid source)'  
to watch out which it belongs to!  
All things above that I've done in order to decrease the time  
of building android tree when you change buildtype,but it will  
also increase the disk space usage at the same time!!!  

