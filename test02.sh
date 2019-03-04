#!/bin/sh
# check that add works combined with commit -a
# commit -a -m works or nothing to commit
./legit.pl init
echo line 1 >a
./legit.pl add a
./legit.pl commit -m 'first commit'
echo line 2 >>a
echo world >b
# the whole add should fail, has error message
./legit.pl add b c
# nothing to commit
./legit.pl commit -m 'second commit'

#if use commit -a -m, add a in current directory to index and commit
./legit.pl commit -a -m 'second commit'


./legit.pl show 0:a
# b doesn't exist in commit 0
./legit.pl show 0:b
./legit.pl show 1:a
./legit.pl show 1:b
# c doesn't exist in commit 1
./legit.pl show 1:c
./legit.pl show :a
./legit.pl show :b
./legit.pl log
./legit.pl commit -a -m 'nothing to commit'
./legit.pl log

echo this is c >c
./legit.pl add b c
./legit.pl commit -m "add file b and c"
./legit.pl log
./legit.pl show 2:a
./legit.pl show 2:b
./legit.pl show 2:c

