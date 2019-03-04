#!/bin/sh
# check rm and rm --cached works without error
# check status 'deleted' and 'unteacked' works
./legit.pl init
echo line 1 >a
./legit.pl add a
echo file >b

./legit.pl commit -m 'first commit'
# a should be same as repo
# b untracked
./legit.pl status

#removed from index, status of a becomes untracked
./legit.pl rm --cached a
./legit.pl status

# remove a from current directory
# status: deleted
rm a
./legit.pl status

# has error, a not in neithor current directory nor index
./legit.pl rm a
./legit.pl status

# remove b from current directory
rm b
./legit.pl status

# create new b
touch b
./legit.pl add b
./legit.pl status

#remove it from current directory, still in index
rm b
./legit.pl status

#remove b from the index
./legit.pl rm --cached b
./legit.pl status

# create another b
touch b
./legit.pl add b
./legit.pl commit -m "second commit"


rm b
# check status here is 'file deleted'
./legit.pl status

./legit.pl rm b
# now status becomes 'deleted'
./legit.pl status

touch c
./legit.pl add c
./legit.pl commit -m "add c"

rm c
./legit.pl status

