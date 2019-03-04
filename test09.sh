#!/bin/sh
# checkout branch
./legit.pl init

#create file a
echo hello >a
./legit.pl add a
./legit.pl commit -m "commit 0"

# create branch b1
./legit.pl branch b1
echo world >>a
./legit.pl checkout b1

#now in the current directory has file a is also hello world
./legit.pl checkout master
#now in the current directory has file a has "hello world"

./legit.pl checkout b1
./legit.pl add a
./legit.pl commit -m "commit 1"

# now checkout to master branch
./legit.pl checkout master
# now the file a in the current directory becomes "hello"

touch c
./legit.pl add c
./legit.pl commit -m "add file c"
./legit.pl checkout b1
# has error message, doesn't exist file c
cat c

# create a file under branch b1
echo hello >d
./legit.pl add d

# checkout to master branch
./legit.pl checkout master
./legit.pl add d
./legit.pl commit -m "add d"

# checkout to branch b1
# d doesn't exist in the branch b1 anymore, has error message
./legit.pl show :d

