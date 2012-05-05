#!/usr/bin/env bash

current_dir=$(realpath $(dirname $0))

test_bare_repo="${current_dir}/kick.git"
test_repo="${current_dir}/kick"

php_file='powerrangers.php'

mkdir $test_bare_repo $test_repo

cd $test_bare_repo
git init --bare > /dev/null 2>&1
cp $current_dir/../hooks/pre-receive hooks
chmod +x hooks/pre-receive

cd $test_repo
git init > /dev/null 2>&1
git remote add origin $test_bare_repo

touch foo
git add foo
git commit -m 'First commit' > /dev/null 2>&1
git push origin master > /dev/null 2>&1

cp $current_dir/$php_file $test_repo
git add $php_file
git commit -m 'No warnings and errors' > /dev/null 2>&1
echo "--------------------First push--------------------"
git push origin master

sed -i 's/#\$f00/\$f00/' $php_file
git add $php_file
git commit -m 'Make a warning' > /dev/null 2>&1
echo -e "\n--------------------Second push--------------------"
git push origin master

sed -i 's/powerRangers/power_ranges/' $php_file
git add $php_file
git commit -m 'Make a error' > /dev/null 2>&1
echo -e "\n--------------------Third push--------------------"
git push origin master

rm $test_bare_repo $test_repo -rf
