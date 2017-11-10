#!/bin/bash
set -eu

# ./image-build -r namazu510/mofumofu.git -t GITHUB-TOKEN -c COMMIT-ID
while getopts r:t:c: OPT
do
  case $OPT in
    "r" ) USER=${OPTARG%%/*} REPO=${OPTARG##*/} ;;
    "t" ) TOKEN=$OPTARG ;;
    "c" ) COMMIT_ID=$OPTARG ;;
  esac
done

mkdir -p repos
rm -rf repos/$REPO

# clone
git clone "https://${USER}:${TOKEN}@github.com/${USER}/${REPO}" repos/$REPO
cd repos/$REPO
git checkout $COMMIT_ID

# build
TAG="${DOCKER_REG}/${USER,,}/${REPO,,}:${COMMIT_ID}"
docker build -t $TAG .

# push
docker push $TAG
