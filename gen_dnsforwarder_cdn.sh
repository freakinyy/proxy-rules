#!/bin/bash

#Gernarate CDN group file for dnsforwarder.

SLIENT=
CURL_EXTARG=''

help() {
    echo " Usage: $0 [options] -o FILE."
	echo " -i, --insecure: Force bypass certificate validation (insecure)."
    echo " -o, --output <FILE>: Output to <FILE>."
    echo " -h, --help: Usage."
}

while [ ${#} -gt 0 ]; do
    case "${1}" in
        --help | -h)
            help
			exit
            ;;
        --insecure | -i)
            CURL_EXTARG='--insecure'
            ;;
		--output | -o)
            OUT_FILE="$2"
            shift
            ;;
        *)
            help
			exit
            ;;
    esac
	shift
done

which mktemp base64 >/dev/null
if [ $? != 0 ]; then
    export PATH=$PATH:/koolshare/bin
fi

# Check path & file name
if [ -z $OUT_FILE ]; then
    echo "Error: Please specify the path to the output file(using -o/--output argument)."
    exit 1
else
    if [ -z ${OUT_FILE##*/} ]; then
        echo "Error: '$OUT_FILE' is a path, not a file."
        exit 1
    else
        if [ ${OUT_FILE}a != ${OUT_FILE%/*}a ] && [ ! -d ${OUT_FILE%/*} ]; then
            echo "Error: Folder do not exist: '${OUT_FILE%/*}'"
            exit 1
        fi
    fi
fi

TMP_DIR=`mktemp -d /tmp/felixonmars2cdn.XXXXXX`
OUT_TMP_FILE="$TMP_DIR/cdn.out.tmp"

echo "Getting CDNs..."
#curl -s -L $CURL_EXTARG 'https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf' | grep -v "^#" | sed "s/server=\///g" | sed "s/\/114.114.114.114//g" | sort | awk '{if ($0!=line) print;line=$0}' > $OUT_TMP_FILE
curl -s -L $CURL_EXTARG 'https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf' | grep -v "^#" | sed "s/server=\///g" | sed "s/\/114.114.114.114//g" | sort | awk '{if ($0!=line) print;line=$0}' > $OUT_TMP_FILE

cat >> $OUT_TMP_FILE <<EOF
protocol udp
server 119.29.29.29:53
parallel off
EOF

filesize=$(ls -l $OUT_TMP_FILE | awk '{print $5}')
if [ "$filesize" -gt 10240 ];then
	cp -f $OUT_TMP_FILE $OUT_FILE
else
	echo "File size is too small, maybe the list file is polluted! Nothing updated for safety."
fi

rm -rf $TMP_DIR

echo "Done."

exit