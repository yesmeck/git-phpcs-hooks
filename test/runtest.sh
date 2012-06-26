#!/usr/bin/env bash

current_dir=$(realpath $(dirname $0))

test_bare_repo="${current_dir}/kick.git"
test_repo="${current_dir}/kick"

php_file='powerrangers.php'


test_pre-commit() {
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
    echo "--------------------No warnings and errors--------------------"
    git commit -m 'No warnings and errors'
    git push origin master > /dev/null 2>&1

    sed -i 's/#\$f00/\$f00/' $php_file
    git add $php_file
    echo -e "\n--------------------Make a warning--------------------"
    git commit -m 'Make a warning'
    git push origin master > /dev/null 2>&1

    sed -i 's/powerRangers/power_ranges/' $php_file
    git add $php_file
    echo -e "\n--------------------Make a error--------------------"
    git commit -m 'Make a error'
    git push origin master > /dev/null 2>&1

    sed -i 's/#\$f11/\$f11/' $php_file
    git add $php_file
    echo -e "\n--------------------Make more warnings--------------------"
    git commit -m 'Make more warnings'
    git push origin master > /dev/null 2>&1

    rm $test_bare_repo $test_repo -rf
}

test_pre-receive() {
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

    echo "--------------------No warnings and errors--------------------"
    git add $php_file
    git commit -m 'No warnings and errors' > /dev/null 2>&1
    git push origin master

    echo -e "\n--------------------Make a warning-------------------"
    sed -i 's/#\$f00/\$f00/' $php_file
    git add $php_file
    git commit -m 'Make a warning' > /dev/null 2>&1
    git push origin master

    echo -e "\n--------------------Make a error--------------------"
    sed -i 's/powerRangers/power_ranges/' $php_file
    git add $php_file
    git commit -m 'Make a error' > /dev/null 2>&1
    git push origin master

    rm $test_bare_repo $test_repo -rf
}

test_post-receive() {
    echo 'test_post-receive'
}


if [[ $# == 0 ]]; then
    test_pre-commit
    test_pre-receive
    test_post-receive
else
    for arg in $@; do
        case $arg in
            pre-commit)
                test_pre-commit
                ;;
            pre-receive)
                test_pre-receive
                ;;
            post-receive)
                test_post-receive
                ;;
            *)
                echo 'Test case not found.'
                ;;
        esac
    done
fi

