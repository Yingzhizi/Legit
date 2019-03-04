#!/bin/sh
# check status of files
./legit.pl init
touch a b c d e
./legit.pl add a b c d e
# check error message 'legit.pl: error: your repository does not have any commits yet'
./legit.pl status
./legit.pl commit -m "first commit"

# rm files from the current directory
rm a b c d e
./legit.pl add a b c d e
# check status "deleted"
./legit.pl status

./legit.pl commit -m "second commit"
# no files output
./legit.pl status

echo hello >a
# a is untracked
./legit.pl status

./legit.pl add a
./legit.pl commit -m "add file a"

echo world >>a
# file changed, but changed not staged to commit
./legit.pl status

./legit.pl add a
# file changed, change staged to commit
./legit.pl status

rm a
# check status file deleted
./legit.pl status

echo new >a
./legit.pl add a
echo file >>a
# check status 'file changed, different changes staged to commit'
./legit.pl status

# cannot rm a, error message occur, stop
./legit.pl rm a b

# doesn't exist b, cannot rm b
./legit.pl rm b
./legit.pl status

