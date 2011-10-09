#!/bin/zsh
export ENV_NAME=pingman
export VIRTUALENV_PATH=~/.virtualenvs/$ENV_NAME
source $VIRTUALENV_PATH/bin/activate
$VIRTUAL_ENV/bin/python rel/files/sample/scripts/pingman.py
