#!/bin/sh
# test checkout branch
./legit.pl init
touch a
./legit.pl add a
./legit.pl commit -m "add a"

./legit.pl branch b1
echo line >>a

#checkout to branch b1
./legit.pl checkout b1
# a is line
cat a
./legit.pl add a
# print out one line which has 'line'
./legit.pl show :a

#checkout to branch master
./legit.pl checkout master
./legit.pl add a
./legit.pl commit -m "update a"
./legit.pl show :a

# checkout to branch b1 again
./legit.pl checkout b1

#print out nothing
./legit.pl show :a

#now rm a in the branch b1
rm a
./legit.pl add a
./legit.pl commit -m "rm a"
# has error, because a is not in the index anymore
./legit.pl show :a

# show log has commit 2 and commit 0
./legit.pl log
# show has commits 2 1 0
./legit.pl show 1:a

# checkout to master branch
./legit.pl checkout master
# actualy has a in the index in this branch
./legit.pl show :a
cat a

./legit.pl rm --cached a
./legit.pl commit -a -m "update"
./legit.pl status

