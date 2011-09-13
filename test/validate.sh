#!/bin/bash

RUBY_PARAMS=$@
if [[ $RUBY_PARAMS == "" ]]; then
  RUBY="ruby"
else
  RUBY="ruby ${RUBY_PARAMS}"
fi

version=`$RUBY -v`
printf "using \"$RUBY\" $version\n"

validation_path="test/validation"
output_path="${validation_path}/output"
if [ ! -d "$output_path" ]; then
  mkdir -p $output_path
fi

function assert {
  result=0
  for p in $@; do
    d=`diff -I 'process [0-9]\+' ${validation_path}/expected/$p ${validation_path}/output/$p`
    if [ $? -ne 0 ]; then
      printf "failed, $p diff:\n"
      printf "$d\n"
      result=1
    fi
  done
      
  if [ $result -eq 0 ]; then
    printf "success\n"
  fi
  return $result
}


function waitline {
  tail -f ${output_path}/$1 |
  while read line; do
    if [[ $line == *$2* ]]; then
      kill `ps -f| grep "tail -f ${output_path}/$1" | grep -v grep| awk '{print $2}'`; 
      break
    fi
  done
}

rm -f ${output_path}/*

TEST="test1-1"
printf "$TEST "
$RUBY ${validation_path}/test1.rb --pattern "%m" start >${output_path}/${TEST} 2>&1 &
waitline ${TEST} "test1 running"
kill -TERM $!
wait $!
assert ${TEST}

TEST="test1-2"
printf "$TEST "
$RUBY ${validation_path}/test1.rb --pattern "%m" -d -v -P "${output_path}/${TEST}.pid" -l "${output_path}/${TEST}-daemon" start >"${output_path}/${TEST}-exe" 2>&1
waitline "${TEST}-daemon" "test1 running"
$RUBY ${validation_path}/test1.rb -P "${output_path}/${TEST}.pid" stop >>"${output_path}/${TEST}-exe" 2>&1
waitline "${TEST}-daemon" ">> Raad service wrapper stopped"
assert "${TEST}-daemon" "${TEST}-exe"

TEST="test2-1"
printf "$TEST "
$RUBY ${validation_path}/test2.rb --pattern "%m" --timeout 2 start >${output_path}/${TEST} 2>&1 &
waitline ${TEST} "test2 running"
kill -TERM $!
wait $!
assert ${TEST}

TEST="test2-2"
printf "$TEST "
$RUBY ${validation_path}/test2.rb --pattern "%m" --timeout 2 -d -P "${output_path}/${TEST}.pid" -l "${output_path}/${TEST}-daemon" start >"${output_path}/${TEST}-exe" 2>&1
waitline "${TEST}-daemon" "test2 running"
$RUBY ${validation_path}/test2.rb --timeout 2 -P "${output_path}/${TEST}.pid" stop >>"${output_path}/${TEST}-exe" 2>&1
waitline "${TEST}-daemon" ">> Raad service wrapper stopped"
assert "${TEST}-daemon" "${TEST}-exe"

TEST="test2-3"
printf "$TEST "
$RUBY ${validation_path}/test2.rb --pattern "%m" --timeout 5 -d -P "${output_path}/${TEST}.pid" -l "${output_path}/${TEST}-daemon" start >"${output_path}/${TEST}-exe" 2>&1
waitline "${TEST}-daemon" "test2 running"
$RUBY ${validation_path}/test2.rb --timeout 2 -P "${output_path}/${TEST}.pid" stop >>"${output_path}/${TEST}-exe" 2>&1
waitline "${TEST}-exe" ">> sending KILL signal to process"
assert "${TEST}-daemon" "${TEST}-exe"
