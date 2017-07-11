#!/usr/bin bash
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

# clone
git clone "https://${USER}:${TOKEN}@github.com/${USER}/${REPO}" $REPO
cd $REPO
git checkout $COMMIT_ID

# build
TAG="reg.k8s.internal.t-lab.cs.teu.ac.jp/${USER}/${REPO}:${COMMIT_ID}"
docker build -t $TAG .

# push
docker push $TAG
