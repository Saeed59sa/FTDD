#!/usr/bin/bash -e

if [ $# -ne 2 ]
  then
    echo "Please provide the Tinkla Version # and Beta version #"
    echo "Usage: build_tinkla_beta.sh v1.7 12"
    exit 0
fi

TINKLA_BETA_VERSION = "$1"
TINKLA_BETA_NUMBER = "$2"

SOURCE_DIR=/data/openpilot
TARGET_DIR=/data/openpilot_beta

ln -sf $TARGET_DIR /data/pythonpath

export GIT_COMMITTER_NAME="BogGyver"
export GIT_COMMITTER_EMAIL="bogdan.butoi@gmail.com"
export GIT_AUTHOR_NAME="BogGyver"
export GIT_AUTHOR_EMAIL="bogdan.butoi@gmail.com"
export GIT_SSH_COMMAND="ssh -i /data/gitkey"

echo "[-] Setting up repo T=$SECONDS"
if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p $TARGET_DIR
  cd $TARGET_DIR
  git init
  git remote add origin git@github.com:boggyver/openpilot.git
fi

echo "[-] fetching public T=$SECONDS"
cd $TARGET_DIR
git prune || true
git remote prune origin || true

echo "[-] bringing devel in sync T=$SECONDS"
#git checkout -f --track origin/tesla_unity_beta
git reset --hard origin/tesla_unity_beta
git checkout  tesla_unity_beta
git clean -xdf


# remove everything except .git
echo "[-] erasing old openpilot T=$SECONDS"
find . -maxdepth 1 -not -path './.git' -not -name '.' -not -name '..' -exec rm -rf '{}' \;

# reset tree and get version
cd $SOURCE_DIR
git clean -xdf
git checkout -- selfdrive/common/version.h
git checkout -- selfdrive/common/tinkla_version.h

VERSION=$(cat selfdrive/common/version.h | awk -F\" '{print $2}')
TINKLAVERSION=$(cat selfdrive/common/tinkla_version.h | awk -F[\"-]  '{print $2}')

# do the files copy
echo "[-] copying files T=$SECONDS"
cd $SOURCE_DIR
cp -pR --parents $(cat $SOURCE_DIR/release/files_common) $TARGET_DIR/

#update version files
echo "#define COMMA_VERSION \"v$TINKLA_BETA_VERSION Beta$TINKLA_BETA_NUMBER ($VERSION)\"" > $TARGET_DIR/selfdrive/common/version.h
echo "#define TINKLA_VERSION \"v$TINKLA_BETA_VERSION Rel ($VERSION)\"" > $TARGET_DIR/selfdrive/common/tinkla_version.h

# test files
if [ ! -z "$DEVEL_TEST" ]; then
  cp -pR --parents tools/ $TARGET_DIR/
fi
# in the directory
cd $TARGET_DIR

rm -f panda/board/obj/panda.bin.signed

echo "[-] committing version $VERSION T=$SECONDS"
git add -f .
git status
git commit -a -m "Tesla Unity v$TINKLA_BETA_VERSION-Beta$TINKLA_BETA_NUMBER (openpilot v$VERSION)"
git push --set-upstream origin tesla_unity_beta

cd $SOURCE_DIR
git checkout selfdrive/common/version.h
git checkout selfdrive/common/tinkla_version.h

# Run build
SCONS_CACHE=1 scons -j3

echo "[-] done T=$SECONDS"
