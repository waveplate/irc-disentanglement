#!/bin/bash

DIS_HOME=${PWD%/*}

filename=$1

# check if filename was supplied
if [ -z "$filename" ]; then
  echo "Usage: $0 <filename> [--continue <file_num>]"
  echo "The following will continue processing and output to todo.test.2.txt"
  echo "  $0 test.txt --continue 2"
  echo "The annotation will continue from wherever it left off"
  exit 1
fi

# get the filename without extension using cut
filename_noext=$(echo $filename | cut -f 1 -d '.')

# check if continue flag was supplied
if [ "$2" == "--continue" ]; then
  append="--append"
  new_file_num=$3
  # get the last linenumber to be processed in the previous run
  last_line=$(tail -n 1 todo.$filename_noext.$new_file_num.annotation.txt)
  last_no=$(echo $last_line | cut -f 1 -d ' ' | cut -f 1 -d ' ')
  test_start=$((last_no + 1))
else
  append=""
  test_start=0
  # check if any files beginning with todo.$filename_noext.* exist
  if ls todo.$filename_noext.* 1> /dev/null 2>&1; then
    latest_file=$(ls -t todo.$filename_noext.* | head -1 | cut -d'.' -f3)
    new_file_num=$((latest_file + 1))
  else
    new_file_num=0
  fi
fi

tmpfile=todo.$filename_noext.$new_file_num
cp $filename ${tmpfile}.txt

if ! [ -f "${tmpfile}.txt.tok" ]; then
  python3 ${DIS_HOME}/tools/preprocessing/dstc8-tokenise.py --vocab ${DIS_HOME}/data/vocab.txt --output-suffix .tok ${tmpfile}.txt
fi

python3 ${DIS_HOME}/src/disentangle.py \
  ${tmpfile} \
  --model ${DIS_HOME}/src/waveplate.dy.model \
  --test ${tmpfile} \
  --test-start $test_start \
  --test-end 1000000000 \
  --hidden 512 \
  --layers 2 \
  --max-dist 100 \
  --dynet-autobatch \
  --nonlin softsign \
  --word-vectors ${DIS_HOME}/data/glove-ubuntu.txt \
  --gpu \
  $append
