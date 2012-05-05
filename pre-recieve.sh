#!/usr/bin/env bash

# 创建临时目录
TMP_DIR=$(mktemp -d)

# 空hash
EMPTY_REF='0000000000000000000000000000000000000000'

# Colors
purple='\033[35m'
red='\033[31m'
red_bold='\033[1;31m'
yellow='\033[33m'
yellow_bold='\033[1;33m'
green='\033[32m'
green_bold='\033[1;32m'
blue='\033[34m'
blue_bold='\033[1;34m'
color_end='\033[0m'

while read oldrev newrev ref
do
    # 当push新分支的时候oldrev会不存在，删除时newrev就不存在
    if [[ $oldrev != $EMPTY_REF && $newrev != $EMPTY_REF ]]; then
        echo -e "\n${purple}CodeSniffer check result:${color_end}"
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
                    msg="$msg${yellow_bold}${warning}${color_end} ${yellow}warnings${color_end} "

                    let "warnings_count = warnings_count + 1"
                fi
                if [[ $error > 0 ]]; then
                    msg="$msg${red_bold}${error}${color_end} ${red}errors${color_end}"

                    let "errors_count = errors_count + 1"
                fi

                echo -e "    $msg"
            fi

            let "checked_file_count = checked_file_count + 1";

        done

        if [[ $checked_file_count == 0 ]]; then
            echo -e "    ${blue_bold}No file was checked.${color_end}"
        elif [[ $warnings_count == 0 && $errors_count == 0 ]]; then
            echo -e "${green_bold}$(cowsay 'Congratulations!!!')${color_end}"
        elif [[ $errors_count  == 0 ]]; then
            echo
            echo -e "    ${blue}Good job, no errors were found!!!${color_end}"
        fi

        echo
        echo -e "http://testing/project/code-sniffer/reporter\n"
    fi
done

# 删除临时目录
rm -rf $TMP_DIR

exit 0
