#!/bin/sh
# check status works
# check commit -a -m works, even if add deleted files
./legit.pl init

touch a b c d e f g

# check when there no add before the ./legit create, commit nothing
./legit.pl commit -m "add files"
./legit.pl commit -a -m "add files"

./legit.pl add a b c d e f g
./legit.pl commit -m "add files"
# the status of all the files is "same as repo"
./legit.pl status

rm a b c d e f g
# the status of all the files is "file deleted"
./legit.pl status

# remove file contain unknown file, has error message
./legit.pl rm a b c f h
#same as above
./legit.pl status

./legit.pl rm a b c
# a, b, c has status "deleted", others is file deleted
./legit.pl status

# file a b c d e f g doesn't exist in status anymore
./legit.pl commit -a -m "update"
./legit.pl status

