function download() { # $1 = url
    processes=`cat /proc/cpuinfo |grep "processor"|wc -l`
    filename="${1##*/}"
    aria2c "$1"
    bashscriptname=`rar lb -p"k-kawaii clara chan ist mein waifu! " "$filename" | sed 's/\r//g' | recode gbk..utf8`
    rar x -ts -p"k-kawaii clara chan ist mein waifu! " "$filename"
    rm "$filename" -f
    echo 'function check114514() { # $1 = checksum file, $2 = link file, and must be runnin'"'"' in downloaded folder, $3 = processes' > thonksette.sh
    echo '    OLD_IFS=$IFS' >> thonksette.sh
    echo "    IFS=\$'\n'" >> thonksette.sh
    echo '    [ "$3" ] && processes="$3" || processes=1' >> thonksette.sh
    echo '    # processes=4' >> thonksette.sh
    echo '    rm ../newaria.txt -f' >> thonksette.sh
    echo '    lines=`wc -l "$1" | cut -f1 -d'"'"' '"'"'`' >> thonksette.sh
    echo '    cat "$1" | grep -v "checksums" > "$1.temp"' >> thonksette.sh
    echo '    split -l "$[lines/processes]" "$1.temp" -d checksumtemp' >> thonksette.sh
    echo '    for file in `ls | grep "checksumtemp"`' >> thonksette.sh
    echo '    do' >> thonksette.sh
    echo '    {' >> thonksette.sh
    echo '        sha512sum -c "$file" > "result.$file.txt"' >> thonksette.sh
    echo '    } &' >> thonksette.sh
    echo '    done' >> thonksette.sh
    echo '    wait' >> thonksette.sh
    echo '    for line in `cat result.checksumtemp* | grep -v "成功" | grep -v "OK"`' >> thonksette.sh
    echo '    do' >> thonksette.sh
    echo '        echo "$line"' >> thonksette.sh
    echo '        filename=`echo $line | cut -d'"'"':'"'"' -f1`' >> thonksette.sh
    echo '        rm "$filename" -f' >> thonksette.sh
    echo '        cat "$2" | sed '"'"':a;N;$!ba;s/\n dir=/|dir=/g'"'"' | grep "$filename" | sed '"'"'s/|dir=/\n dir=/g'"'"' >> ../newaria.txt' >> thonksette.sh
    echo '    done' >> thonksette.sh
    echo '    rm checksumtemp* result.checksumtemp* "$1.temp" -f' >> thonksette.sh
    echo '    IFS=$OLD_IFS' >> thonksette.sh
    echo '}' >> thonksette.sh
    cat "$bashscriptname" | sed "s/aria2c /[ ! -d downloaded ] \&\& aria2c /g;s/cd downloaded/cd downloaded\ncheck114514 ..\/checksums ..\/aria2temp $processes\nwhile [ -s ..\/newaria.txt ]; do cd ..; aria2c -k 1M -x 128 -s 128 -j 64 -R -c --auto-file-renaming=false -i newaria.txt; cd downloaded; check114514 ..\/checksums ..\/aria2temp $processes; done/g;s/if.*then  //g;s/exit 0.*/exit 0/g;s/sha512sum -c ..\/checksums > results//g" >> thonksette.sh
    rm "$bashscriptname" -f
    mv thonksette.sh "$bashscriptname"
    bash "$bashscriptname"
    rm "$bashscriptname" -f
}

download "$1"
