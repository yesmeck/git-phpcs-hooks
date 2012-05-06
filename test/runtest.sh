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
cp $current_dir/../hooks/pre-commit .git/hooks
chmod +x .git/hooks/pre-commit

touch foo
git add foo
git commit -m 'First commit' > /dev/null 2>&1
git push origin master > /dev/null 2>&1

cp $current_dir/$php_file $test_repo
git add $php_file
echo "--------------------Commit test--------------------"
git commit -m 'No warnings and errors'
echo -e "\n--------------------Push test--------------------"
git push origin master

sed -i 's/#\$f00/\$f00/' $php_file
git add $php_file
echo -e "\n--------------------Commit test--------------------"
git commit -m 'Make a warning'
echo -e "\n--------------------Push test--------------------"
git push origin master

sed -i 's/powerRangers/power_ranges/' $php_file
git add $php_file
echo -e "\n--------------------Commit test--------------------"
git commit -m 'Make a error'
echo -e "\n--------------------Push test--------------------"
git push origin master

rm $test_bare_repo $test_repo -rf
