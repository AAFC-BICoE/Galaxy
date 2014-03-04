#!/bin/bash

MY_PATH="`dirname \"$0\"`"

java -cp $CLASSPATH:$MY_PATH/bin $*
