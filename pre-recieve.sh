#!/usr/bin/env bash

# 创建临时目录
TMP_DIR=$(mktemp -d)

# 空hash
EMPTY_REF='0000000000000000000000000000000000000000'

# Colors
PURPLE='\033[35m'
RED='\033[31m'
RED_BOLD='\033[1;31m'
YELLOW='\033[33m'
YELLOW_BOLD='\033[1;33m'
GREEN='\033[32m'
GREEN_BOLD='\033[1;32m'
BLUE='\033[34m'
BLUE_BOLD='\033[1;34m'
COLOR_END='\033[0m'

while read oldrev newrev ref
do
    # 当push新分支的时候oldrev会不存在，删除时newrev就不存在
    if [[ $oldrev != $EMPTY_REF && $newrev != $EMPTY_REF ]]; then
        echo -e "\n${PURPLE}CodeSniffer check result:${COLOR_END}"
        echo
        # 警告数
        warnings_count=0
        # 错误数
        errors_count=0
        # 被检查了的文件数
        checked_file_count=0
        # 找出哪些文件被更新了
        for line in $(git diff-tree -r $oldrev..$newrev | grep -oP '.*\.(js|php)' | awk '{print $5$6}')
        do
            # 文件状态
            # D: deleted
            # A: added
            # M: modified
            status=$(echo $line | grep -o '^.')

            # 不检查被删除的文件
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

                msg="${file}: "

                if [[ $warning > 0 ]]; then
                    msg="$msg${YELLOW_BOLD}${warning}${COLOR_END} ${YELLOW}warnings${COLOR_END} "

                    let "warnings_count = warnings_count + 1"
                fi
                if [[ $error > 0 ]]; then
                    msg="$msg${RED_BOLD}${error}${COLOR_END} ${RED}errors${COLOR_END}"

                    let "errors_count = errors_count + 1"
                fi

                echo -e "    $msg"
            fi

            let "checked_file_count = checked_file_count + 1";

        done

        if [[ $checked_file_count == 0 ]]; then
            echo -e "    ${BLUE_BOLD}No file was checked.${COLOR_END}"
        elif [[ $warnings_count == 0 && $errors_count == 0 ]]; then
            echo -e "${GREEN_BOLD}$(cowsay 'Congratulations!!!')${COLOR_END}"
        elif [[ $errors_count  == 0 ]]; then
            echo
            echo -e "    ${BLUE}Good job, no errors were found!!!${COLOR_END}"
        fi

        echo
        echo -e "http://testing/project/code-sniffer/reporter\n"
    fi
done

# 删除临时目录
rm -rf $TMP_DIR

exit 0
