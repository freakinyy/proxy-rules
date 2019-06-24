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
    #exit 1
	OUT_FILE="default.xml"
else
    if [ -z ${OUT_FILE##*/} ]; then
        echo "Error: '$OUT_FILE' is a path, not a file."
        #exit 1
		OUT_FILE="default.xml"
    else
        if [ ${OUT_FILE}a != ${OUT_FILE%/*}a ] && [ ! -d ${OUT_FILE%/*} ]; then
            echo "Error: Folder do not exist: '${OUT_FILE%/*}'"
            #exit 1
			OUT_FILE="default.xml"
        fi
    fi
fi

TMP_DIR=`mktemp -d /tmp/gen_proxycap_xml.XXXXXX`
OUT_TMP_FILE="$TMP_DIR/gen_proxycap_xml.out.tmp"

echo "Getting China IPs..."
curl -s -L $CURL_EXTARG 'https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $TMP_DIR/Chn_IPs.txt
curl -s -L $CURL_EXTARG 'https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv6 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, $5) }' > $TMP_DIR/Chn_IPs.txt

echo "Generating $OUT_FILE..."

cat >> $OUT_TMP_FILE <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<proxycap_ruleset version="525">
  <proxy_servers>
    <proxy_server
      name="Proxy_US"
      type="socks5"
      hostname="localhost"
      port="1081"
      auth_method="none"
      is_default="true"
    />
  </proxy_servers>
  <routing_rules>
    <routing_rule
      name="Local_IPs"
      action="direct"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <ip_addresses>
        <ip_range ip="0.0.0.0" mask="8" />
        <ip_range ip="10.0.0.0" mask="8" />
        <ip_range ip="100.64.0.0" mask="10" />
        <ip_range ip="169.254.0.0" mask="16" />
        <ip_range ip="172.16.0.0" mask="12" />
        <ip_range ip="192.0.0.0" mask="24" />
        <ip_range ip="192.0.2.0" mask="24" />
        <ip_range ip="192.88.99.0" mask="24" />
        <ip_range ip="192.168.0.0" mask="16" />
        <ip_range ip="198.18.0.0" mask="15" />
        <ip_range ip="198.51.100.0" mask="24" />
        <ip_range ip="203.0.113.0" mask="24" />
        <ip_range ip="224.0.0.0" mask="4" />
        <ip_range ip="240.0.0.0" mask="4" />
        <ip_range ip="255.255.255.255" mask="32" />
        <ip_range ip="::" mask="128" />
        <ip_range ip="100::" mask="64" />
        <ip_range ip="2001::" mask="32" />
        <ip_range ip="2001:20::" mask="28" />
        <ip_range ip="2001:db8::" mask="32" />
        <ip_range ip="2002::" mask="16" />
        <ip_range ip="fc00::" mask="7" />
        <ip_range ip="fe80::" mask="10" />
        <ip_range ip="ff00::" mask="8" />
      </ip_addresses>
    </routing_rule>
    <routing_rule
      name="Proxy_Prog"
      action="direct"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <programs>
        <program path="Shadowsocks.exe" dir_included="false" />
        <program path="obfs-local.exe" dir_included="false" />
        <program path="v2ray-plugin.exe" dir_included="false" />
        <program path="BitComet.exe" dir_included="false" />
      </programs>
    </routing_rule>
    <routing_rule
      name="Chn_IPs"
      action="direct"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <ip_addresses>
EOF
cat $TMP_DIR/Chn_IPs.txt | sed "s/^/        <ip_range ip=\"/g" | sed "s/\//\" mask=\"/g" | sed "s/$/\" \/>/g" | sort | awk '{if ($0!=line) print;line=$0}'  >> $OUT_TMP_FILE

cat >> $OUT_TMP_FILE <<EOF
      </ip_addresses>
    </routing_rule>
    <routing_rule
      name="Others"
      action="proxy"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <proxy_or_chain name="Proxy_US" />
    </routing_rule>
  </routing_rules>
</proxycap_ruleset>
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
