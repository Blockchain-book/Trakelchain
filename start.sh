#!/usr/bin/env bash

#set -e

# test the env
# 检查环境
if ! type go > /dev/null; then
     echo -e "Please install the go env correctly!"
     exit 1
fi
if ! type govendor > /dev/null; then
    # install foobar here
    echo -e "Please install the `govendor`, just type:\ngo get -u github.com/kardianos/govendor"
    exit 1
fi
if ! type jq > /dev/null; then
    echo -e "Please install the `jq` to parse the json file \n just type: \n sudo apt-get install jq"
    exit 1
fi


#执行测试
for((j=1;j<=4;j++))
do
    gnome-terminal -x bash -c "cd trakelchain && ./trakelchain -o ${j} -l 800${j} -t 808${j}"
    # this command for run 4 in 1 window
#    ./hyperchain -o ${j} -l 800${j} -t 808${j}
done


