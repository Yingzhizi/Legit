#!/bin/sh
#test error message of log and show commit:file
# 1) doesn't has any commit yet
#    should has error message "legit.pl: error: your repository does not have any commits yet"
./legit.pl init
touch a
./legit.pl add a
./legit.pl log
./legit.pl show
./legit.pl status
./legit.pl branch

#2) has commit
./legit.pl commit -m "add file a"
# log
#   i) incorrect format, error message
./legit.pl log incorrect
#   ii) correct format
./legit.pl log

# show
#   i) file want to show doesn't in the index :filename
./legit.pl show :b
#   ii) file want to show doesn't exist in specific commit
./legit.pl show 0:b
#   iii) doesn't have a specific commit
./legit.pl show 9:a
./legit.pl show *:a
#   iv) has wrong object, error message "legit.pl: error: invalid object"
./legit.pl show 9
#   v) has wrong format, error "usage: legit.pl show <commit>:<filename>"
./legit.pl show a b c
#   vi) has invalid file format, error "invalid filename"
./legit.pl show 0:incorrect@file

# correct
./legit.pl show 0:a

