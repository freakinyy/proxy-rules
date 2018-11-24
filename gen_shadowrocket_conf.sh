#!/bin/sh

#Gernarate xml file including rules of local ips, local names,  proxyee-down, librabry names, Jpan names china ips and china names for proxycap.

SLIENT=
CURL_EXTARG=''

help() {
    echo " Usage: sh $0 [options] -o FILE."
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

TMP_DIR=`mktemp -d /tmp/gen_shadowrocket_conf.XXXXXX`
OUT_TMP_FILE="$TMP_DIR/gen_shadowrocket_conf.out.tmp"

echo "Getting China IPs..."
curl -s -L $CURL_EXTARG 'https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $TMP_DIR/Chn_IPs.txt

echo "Getting China Names..."
curl -s -L $CURL_EXTARG 'https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf' | grep -v "^#" | sed "s/server=\///g" | sed "s/\/114.114.114.114//g" | sort | awk '{if ($0!=line) print;line=$0}' > $TMP_DIR/Chn_Names.txt

echo "Generating $OUT_FILE..."

cat >> $OUT_TMP_FILE <<EOF
# Shadowrocket: 2018-11-24 22:28:10
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, e.crashlytics.com, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = 


[Rule]
EOF
cat $TMP_DIR/Chn_IPs.txt | sed "s/^/IP-CIDR,/g" | sed "s/$/,DIRECT/g" | sort | awk '{if ($0!=line) print;line=$0}' >> $OUT_TMP_FILE

cat $TMP_DIR/Chn_Names.txt | sed "s/^/DOMAIN-SUFFIX,/g" | sed "s/$/,DIRECT/g" | sort | awk '{if ($0!=line) print;line=$0}' >> $OUT_TMP_FILE

cat >> $OUT_TMP_FILE <<EOF
FINAL,*,PROXY,force-remote-dns
[Host]
localhost = 127.0.0.1

EOF

filesize=$(ls -l $OUT_TMP_FILE | awk '{print $5}')
if [ "$filesize" -gt 10240 ];then
	cp -f $OUT_TMP_FILE $OUT_FILE
else
	echo "File size is too small, maybe the list file is polluted! Nothing updated for safety."
fi

rm -rf $TMP_DIR

echo "All Done!"

exit
