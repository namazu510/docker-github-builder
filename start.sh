#!/bin/sh
set -eu

# Enviroment
export DOCKER_REG="docker-reg.gallery.local"

# git pull
bundle install --path vendor/bundler
bundle exec ruby main.rb
