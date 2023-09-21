tmpfile="/tmp/barbruh"
delimiter="1145141919810"
processes=32
webhookurl[0]=""
webhookurl[1]=""
webhookurl[2]=""
webhookurl[3]=""
webhookurl[4]=""
webhookurl[5]=""
webhookurl[6]=""
webhookurl[7]=""
webhookurl[8]=""
webhookurl[9]=""
webhookurl[10]=""
webhookurl[11]=""
webhookurl[12]=""
webhookurl[13]=""
webhookurl[14]=""
webhookurl[15]=""
webhookurl[16]=""
webhookurl[17]=""
webhookurl[18]=""
webhookurl[19]=""
webhookurl[20]=""
webhookurl[21]=""
webhookurl[22]=""
webhookurl[23]=""
webhookurl[24]=""
webhookurl[25]=""
webhookurl[26]=""
webhookurl[27]=""
webhookurl[28]=""
webhookurl[29]=""
webhookurl[30]=""
webhookurl[31]=""

function upload() {
    curl "$1" -X POST  \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:95.0) Gecko/20100101 Firefox/95.0'  \
    -H 'Accept: */*'  \
    -H 'Accept-Language: en-US'  \
    -H "Content-Type: multipart/form-data; boundary=---------------------------$delimiter"  \
    -H 'Connection: keep-alive'  \
    -H 'Sec-Fetch-Dest: empty'  \
    -H 'Sec-Fetch-Mode: cors'  \
    -H 'Sec-Fetch-Site: same-origin'  \
    -H 'Pragma: no-cache'  \
    -H 'Cache-Control: no-cache'  \
    -H 'TE: trailers' \
    --data-binary "@-"
}

function formdata_v4(){ # $1 = filepath, $2 = pos, $3 = processid id, $4 = filename
    local attachments=""
    local fileid=0
    local filepath="$1"
    local pos="$2"
    local processid="$3"
    local filename="$4"
    let maxfilesize=16*1024*1024+256
    local mimetype=`file -b --mime-type "$filepath"`
    local line1=$'Content-Disposition: form-data; name="files['"$fileid"']"; filename="'"$filename"'"'
    local line2=$'Content-Type: '"$mimetype"
    echo -n "-----------------------------$delimiter"$'\r\n'"$line1"$'\r\n'"$line2"$'\r\n\r\n'
    local segmentchecksum=`tail -c +$pos "$filepath" | head -c $maxfilesize | sha512sum`
    echo "${segmentchecksum/-/}$filename" >> "$tmpfile.checksums.$processid"
    tail -c +$pos "$filepath" | head -c $maxfilesize
    echo -n $'\r\n'
    local attachment=$'{"id":"'"$fileid"'","filename":"'"$filename"'"}'
    local line4=$'Content-Disposition: form-data; name="payload_json"'
    local line5=$'{"content":"","type":0,"sticker_ids":[],"attachments":['"$attachment"']}'
    echo -n "-----------------------------$delimiter"$'\r\n'"$line4"$'\r\n\r\n'"$line5"$'\r\n'"-----------------------------$delimiter--"$'\r\n'
}

function upload_subprocess() { # $1 = process id
    local processid="$1"
    local filesinprocess=`cat "$tmpfile.list.$processid" | wc -l`
    processedfiles[$processid]=0
    local processedfiles=0
    for line in `cat "$tmpfile.list.$processid"`
    do
        local filepath=`echo "$line" | cut -f1 -d\|`
        local pos=`echo "$line" | cut -f2 -d\|`
        local processid=`echo "$line" | cut -f3 -d\|`
        local filename=`echo "$line" | cut -f4 -d\|`
        local url=""
        local result=""
        while [ "$url" = "" ]
        do
            result=`formdata_v4 "$filepath" "$pos" "$processid" "$filename" | upload "${webhookurl[$processid]}"`
            url=`echo "$result" | sed 's/\[/\n/g' | grep "filename" | sed 's/,/\n/g' | grep '"url":' | sed 's/"/\n/g' | grep "http"`
        done
        let processedfiles[$processid]++
        echo -e "\e[36m$url\e[0m uploaded by process \e[32m$processid\e[0m, file \e[36m${processedfiles[$processid]}\e[0m/\e[32m$filesinprocess\e[0m"
        echo "$url" >> "$tmpfile.aria2.$processid"
        echo " dir=downloaded" >> "$tmpfile.aria2.$processid"
        sleep 1
    done
}

function beegupload_v2() { # $1 = file path
    OLD_IFS=$IFS
    IFS=$'\n'
    let maxfilesize=16*1024*1024+256
    rm "$tmpfile"* -f
    echo -n "" > "$tmpfile"
    echo 'OLD_IFS=$IFS' >> "$tmpfile"
    echo 'IFS=$'"'\n'" >> "$tmpfile"
    
    filepath="$1"
    filename="${filepath##*/}"
    
    mimetype=`file -b --mime-type "$filepath"`
    size=`ls -l "$filepath" | awk '{ print $5 }'`
    
    mainchecksum=`sha512sum "$filepath"`
    # mainchecksum="${mainchecksum/$filepath/$filename}"
    mainchecksumfilename="${mainchecksum%% *}"
    mainchecksum="$mainchecksumfilename  $filename"
    
    echo "cat > checksums <<EOF" >> "$tmpfile"
    
    totalfiles=0
    for pos in `seq 1 $maxfilesize $size`
    do
        newfilename="$mainchecksumfilename.part$totalfiles"
        processid=$[totalfiles%processes]
        echo "$filepath|$pos|$processid|$newfilename" >> "$tmpfile.list.$processid"
        let totalfiles++
    done
    
    for processid in `seq 0 $[processes-1]`
    do
    {
        upload_subprocess "$processid"
    } &
    done
    wait
    
    for processid in `seq 0 $[processes-1]`
    do
        cat "$tmpfile.checksums.$processid" >> "$tmpfile"
        rm "$tmpfile.checksums.$processid" -f
    done
    echo "$mainchecksum" >> "$tmpfile"
    echo "EOF" >> "$tmpfile"
    
    echo "cat > aria2temp <<EOF" >> "$tmpfile"
    for processid in `seq 0 $[processes-1]`
    do
        cat "$tmpfile.aria2.$processid" >> "$tmpfile"
        rm "$tmpfile.aria2.$processid" -f
        rm "$tmpfile.list.$processid" -f
    done
    echo "EOF" >> "$tmpfile"
    
    echo "aria2c -k 1M -x 128 -s 128 -j 64 -R -c --auto-file-renaming=false -i aria2temp" >> "$tmpfile"
    echo "cd downloaded" >> "$tmpfile"
    echo "echo -n "" > \"$filename\"" >> "$tmpfile"
    echo $'for part in `seq 0 '"$[totalfiles-1]"'`; do cat "'"$mainchecksumfilename"'.part$part" >> "'"$filename"'"; done' >> "$tmpfile"
    echo "sha512sum -c ../checksums > results" >> "$tmpfile"
    echo $'if [ `cat results | grep -cv "成功"` -eq 0 -o `cat results | grep -cv "OK"` -eq 0 ] ; then  mv "'"$filename"'" ../; cd ../; rm downloaded/ aria2temp checksums -rf; exit 0; else echo "barbruh"; for file in `cat results | grep -v "成功" | sed "s/:.*//g"`; do rm "$file" -f; done; exit 114514; fi' >> "$tmpfile"
    echo 'IFS=$OLD_IFS' >> "$tmpfile"
    
    mv "$tmpfile" "${filename%.*}.metadata.sh"
    rar a -df -v8274094B -ep1 -htb -m5 -ma5 -rr5 -ts -tsp -ol -hp"k-kawaii clara chan ist mein waifu! " "${filename%.*}.metadata.rar" "${filename%.*}.metadata.sh"
    result=`formdata_v4 "${filename%.*}.metadata.rar" 1 0 "${filename%.*}.$size.metadata.rar" | upload "${webhookurl[0]}"`
    url=`echo "$result" | sed 's/\[/\n/g' | grep "filename" | sed 's/,/\n/g' | grep '"url":' | sed 's/"/\n/g' | grep "http"`
    curl "$webhookurl" -F "payload_json={\"content\":\"$url\",\"username\":\"EulaAAAAAAAA\"}"
    echo "$url" >> /root/localdb.txt
    echo "$filepath|$url" >> results.txt
    rm "${filename%.*}.metadata.rar" "$tmpfile"* -f
    
    IFS=$OLD_IFS
}

beegupload_v2 "$1"
