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
