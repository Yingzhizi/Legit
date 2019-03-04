#!/bin/sh
# error of branch
./legit.pl init
# error message - haven't commit yet
./legit.pl branch
echo line1 >a
./legit.pl add a
# error message - haven't commit yet
./legit.pl branch

./legit.pl commit -m "add a"
# current branch is master
./legit.pl branch

#./legit.pl checkout without argument
# usage: legit.pl checkout <branch>
./legit.pl checkout

# create branch 1
./legit.pl branch branch1
# switch to branch 1
./legit.pl checkout branch1
./legit.pl log
./legit.pl show :a
./legit.pl show 0:a

# checkout to non exist branch
./legit.pl checkout non-exist
./legit.pl checkout master
./legit.pl log
# create another branch
./legit.pl branch branch2

# create a branch has already exist
./legit.pl branch branch2

# list the current branchs
./legit.pl branch

