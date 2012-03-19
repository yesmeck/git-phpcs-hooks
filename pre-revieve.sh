#!/usr/bin/env bash

# 创建临时目录
TMP_DIR=$(mktemp -d)

# 空hash
EMPTY_REF='0000000000000000000000000000000000000000'

while read oldrev newrev ref
do
    # 当push新分支的时候oldrev会不存在，删除时newrev就不存在
    if [[ $oldrev != $EMPTY_REF && $newrev != $EMPTY_REF ]]; then
        echo 'CodeSniffer check result:'
        # 找出哪些文件被更新了
        for file in $(git diff-tree -r $oldrev..$newrev | awk '{print $6}')
        do
            # 为文件创建目录
            mkdir -p $(dirname $TMP_DIR/$file)
            # 保存文件内容
            git show $newrev:$file > $TMP_DIR/$file

            if [[ $(echo $file | grep -e '.php') ]]; then
                STANDARD='Zend'
            fi

            if [[ $(echo $file | grep -e '.js') ]]; then
                STANDARD='Closure_Linter'
            fi

            output=$(phpcs --report=summary --standard=$STANDARD $TMP_DIR/$file)

            warning=$(echo $output | grep -oP '([0-9]+) WARNING' | grep -oP '[0-9]+')
            error=$(echo $output | grep -oP '([0-9]+) ERROR' | grep -oP '[0-9]+')

            echo "    /${file}: ${error} errors, ${warning} warnings"
        done
    fi
done

# 删除临时目录
rm -rf $TMP_DIR

exit 1
