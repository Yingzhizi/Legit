#!/bin/sh
# check the increment of commits works
# check log works and print in the correct order
./legit.pl init
echo line 1 >a
./legit.pl add a
./legit.pl commit -m '1'

echo line 2 >>a
./legit.pl add a
./legit.pl commit -m '2'

echo line 3 >>a
./legit.pl add a
./legit.pl commit -m '3'

echo line 4 >>a
./legit.pl add a
./legit.pl commit -m '4'

echo line 5 >>a
./legit.pl add a
./legit.pl commit -m '5'

echo line 6 >>a
./legit.pl add a
./legit.pl commit -m '6'

echo line 7 >>a
./legit.pl add a
./legit.pl commit -m '7'

echo line 8 >>a
./legit.pl add a
./legit.pl commit -m '8'

echo line 9 >>a
./legit.pl add a
./legit.pl commit -m '9'

echo line 10 >>a
./legit.pl add a
./legit.pl commit -m '10'

echo line 11 >>a
./legit.pl add a
./legit.pl commit -m '11'

echo line 12 >>a
./legit.pl add a
./legit.pl commit -m '12'

echo line 13 >>a
./legit.pl add a
./legit.pl commit -m '13'

./legit.pl log

./legit.pl show 0:a
./legit.pl show 1:a
./legit.pl show 2:a
./legit.pl show 12:a

