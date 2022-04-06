#!/bin/bash

DOT_FILES_DIR=$(dirname $0)
echo "Copy fish_variables to fish folder"
cp ${DOT_FILES_DIR}/fish_variables ${DOT_FILES_DIR}/fish/fish_variables
