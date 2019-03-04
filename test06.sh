#!/bin/sh
# 1)test error messgae
# 2)test any commands has error message if doesn'e exist ./legit
# 3)test add error message
./legit.pl
./legit.pl unknown
./legit.pl add a
./legit.pl commit -m "hello"
./legit.pl log
./legit.pl show :a
./legit.pl commit -a -m "nothing"
./legit.pl rm a
./legit.pl status
./legit.pl branch

# legit init first
./legit.pl init

# init again, show error message .legit has already exist
./legit.pl init

# test ./legit add without argument, has error message
./legit.pl add

# test ./legit add has invalid file name
touch invalid@file
# cannot add to the file, return error message
./legit.pl add invalid@file

# test ./legit add unexist file
# has error, cannot open this file
./legit.pl add non-exist

# test ./legit add removed files
echo testAdd >a
./legit.pl add a
rm a
# rm file a from index
./legit.pl add a

echo testAdd >a
./legit.pl add a
./legit.pl commit -m "add a"

rm a
# rm file from index and last commit
./legit.pl add a

