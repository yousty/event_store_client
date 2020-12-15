# !/bin/bash

# Prerequisites
#
#   Make sure you have the following installed:
#     - a recent ruby (needed for rubocop, overcommit and docker-sync)
#     - brew (needed to install missing tools)
#     - docker
#
# Usage:
#
#   git clone git@github.com:yousty/professional.git
#   cd professional
#   bin/setup-dev.sh -p PASS_PHRASE -t GEMFURY_TOKEN
#   To skip seeds add -s false option
#

help()
{
   echo ""
   echo "USAGE: Pre-execution requirements:"
   echo "\trun: git clone git@github.com:yousty/professional.git && cd professional"
   echo ""
   echo "\t$0 -p PASS_PHRASE -t GEMFURY_TOKEN -s false"
   echo "\t-p PASS_PHRASE to decrypt environment files for development. Check 1Password to access it."
   echo "\t-t GEMFURY_TOKEN required to install private gems. Check 1Password to access it."
   echo "\t-s Optional, default: true. Specify if seeding scripts should be run or skipped."
   exit 1 # Exit script after printing help
}

while getopts "p:t:s:" opt
do
   case "$opt" in
      p ) phrase="$OPTARG" ;;
      t ) token="$OPTARG" ;;
      s ) seed="$OPTARG" ;;
      ? ) help ;; # Print help in case parameter is non-existent
   esac
done

# Print help in case required parameters are empty
if [ -z "$phrase" ] || [ -z "$token" ]
then
  echo $phrase
  echo "Some or all of the required parameters are empty";
  help
fi

docker build --build-arg GEM_FURY_TOKEN=$token -t yousty/ecs:dev -f Dockerfile .
docker build --build-arg GEM_FURY_TOKEN=$token -t yousty/ecs:test -f Dockerfile.test .
docker build --build-arg GEM_FURY_TOKEN=$token -t yousty/encryptor:dev -f ../encryptor/Dockerfile.dev ../encryptor

echo ---------------------- Decrypting environment files ----------------------
if ! [ -x "$(command -v gpg)" ]; then
  echo Installing gnupg...
  if ! [ -x "$(command -v brew)" ]; then
    echo "Aborting, please install home brew first"
  else
    brew install gnupg
  fi
fi

if ! [ -f ".env_encryptor" ]; then
  echo $phrase | gpg --batch --yes --passphrase-fd 0 -d ../encryptor/env_encryptor.gpg > .env_encryptor
else
  echo .env_encryptor already exists.
fi

RUBOCOP_VERSION="0.77.0"
RUBOCOP_PERFORMANCE_VERSION="1.5.1"
RUBOCOP_RAILS_VERSION="2.4.0"

echo ---------------------- Installing docker-sync ----------------------
if ! [ -x "$(command -v docker-sync-stack)" ]; then
  gem install docker-sync
fi

echo ---------------------- Installing rubocop ----------------------
if ! [ -x "$(command -v rubocop)" ]; then
  gem install rubocop -v $RUBOCOP_VERSION
  gem install rubocop-performance -v $RUBOCOP_PERFORMANCE_VERSION
  gem install rubocop-rails -v $RUBOCOP_RAILS_VERSION
fi

echo ---------------------- Installing overcommit ----------------------
if ! [ -x "$(command -v overcommit)" ]; then
  gem install overcommit
fi
overcommit --install

echo
echo ---------------------- Professional development setup completed ----------------------
