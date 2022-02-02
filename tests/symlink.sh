#!/usr/bin/bash

TEST_FILE="/usr/bin/apropos"
echo "cygpath -w ${TEST_FILE} returns $(cygpath -w ${TEST_FILE})"
# don't convert using cygpath -w, as that canonicalizes symlinks ?!?
TEST_FILE_W="C:\cygwin\bin\apropos"

# check the symlink we're going to do checks on exists
if [ ! -L ${TEST_FILE} ]; then
  echo "This test assumes ${TEST_FILE} exists and is a symlink"
  exit 1
fi

# check the symlink was created in the way expected
case ${CYGWIN} in
  *sys*)
    cmd /c "dir /AS ${TEST_FILE_W}" | grep "21"
    ;;

  *native*)
    cmd /c "dir /AL ${TEST_FILE_W}" | grep "<SYMLINK>"
    ;;

  *wsl*)
    fsutil reparsepoint query ${TEST_FILE_W} | grep "0xa000001d"
    ;;
esac
