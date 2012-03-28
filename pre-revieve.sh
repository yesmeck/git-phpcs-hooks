#!/usr/bin/env bash

# 创建临时目录
TMP_DIR=$(mktemp -d)

# 空hash
EMPTY_REF='0000000000000000000000000000000000000000'

while read oldrev newrev ref
do
    # 当push新分支的时候oldrev会不存在，删除时newrev就不存在
    if [[ $oldrev != $EMPTY_REF && $newrev != $EMPTY_REF ]]; then
        echo -e '\n\033[35mCodeSniffer check result:\033[0m'
        # 找出哪些文件被更新了
        for line in $(git diff-tree -r $oldrev..$newrev | awk '{print $5$6}')
        do
            # 文件状态
            # D: deleted
            # A: added
            # M: modified
            status=$(echo $line | grep -o '^.')

            if [[ $status == 'D' ]]; then
                continue
            fi

            # 文件名
            file=$(echo $line | sed 's/^.//')

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

            if [[ $warning || $error ]]; then
                echo -n "    ${file}: "
                echo -en "\033[1;33m${warning}\033[0m \033[33mwarnings\033[0m, "
                echo -e "\033[1;31m${error}\033[0m \033[31merrors\033[0m"
            fi

        done

        echo -e "http://testing/project/code-sniffer/reporter\n";
    fi
done

# 删除临时目录
rm -rf $TMP_DIR

exit 0
