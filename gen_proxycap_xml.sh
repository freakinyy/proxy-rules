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

TMP_DIR=`mktemp -d /tmp/gen_proxycap_xml.XXXXXX`
OUT_TMP_FILE="$TMP_DIR/gen_proxycap_xml.out.tmp"

echo "Getting China IPs..."
curl -s -L $CURL_EXTARG 'https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $TMP_DIR/Chn_IPs.txt

echo "Getting China Names..."
curl -s -L $CURL_EXTARG 'https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf' | grep -v "^#" | sed "s/server=\///g" | sed "s/\/114.114.114.114//g" | sort | awk '{if ($0!=line) print;line=$0}' > $TMP_DIR/Chn_Names.txt

echo "Generating $OUT_FILE..."

cat >> $OUT_TMP_FILE <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<proxycap_ruleset version="525">
  <proxy_servers>
    <proxy_server
      name="Proxy_US"
      type="socks5"
      hostname="localhost"
      port="1080"
      auth_method="none"
      is_default="true"
    />
    <proxy_server
      name="Proxy_JP"
      type="socks5"
      hostname="localhost"
      port="1081"
      auth_method="none"
      is_default="false"
    />
    <proxy_server
      name="Proxy_HFUT"
      type="socks5"
      hostname="localhost"
      port="1082"
      auth_method="none"
      is_default="false"
    />
  </proxy_servers>
  <proxy_chains>
    <proxy_chain name="Chain_US->JP">
       <proxy_server name="Proxy_US" />
       <proxy_server name="Proxy_JP" />
    </proxy_chain>
  </proxy_chains>
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
        <ip_range ip="127.0.0.0" mask="9" />
        <ip_range ip="169.254.0.0" mask="16" />
        <ip_range ip="172.16.0.0" mask="12" />
        <ip_range ip="192.168.0.0" mask="16" />
        <ip_range ip="224.0.0.0" mask="4" />
        <ip_range ip="240.0.0.0" mask="4" />
      </ip_addresses>
    </routing_rule>
    <routing_rule
      name="Local_Names"
      action="direct"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <hostnames>
        <hostname wildcard="localhost" />
        <hostname wildcard="ubuntu_server" />
        <hostname wildcard="openwrt" />
        <hostname wildcard="wrt32x" />
        <hostname wildcard="freakinyy-tft5" />
        <hostname wildcard="freakinyy-cui8" />
        <hostname wildcard="*.localhost" />
        <hostname wildcard="*.ubuntu_server" />
        <hostname wildcard="*.openwrt" />
        <hostname wildcard="*.wrt32x" />
        <hostname wildcard="*.freakinyy-tft5" />
        <hostname wildcard="*.freakinyy-cui8" />
      </hostnames>
    </routing_rule>
    <routing_rule
      name="Proxy_IPs"
      action="direct"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <ip_addresses>
        <ip_range ip="89.208.248.169" mask="32" />
        <ip_range ip="97.64.124.173" mask="32" />
        <ip_range ip="185.183.84.250" mask="32" />
        <ip_range ip="185.186.146.97" mask="32" />
        <ip_range ip="107.175.184.151" mask="32" />
        <ip_range ip="119.82.24.235" mask="32" />
      </ip_addresses>
    </routing_rule>
    <routing_rule
      name="Proxy_Names"
      action="direct"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <hostnames>
        <hostname wildcard="*.hellowzm.cn" />
      </hostnames>
    </routing_rule>
    <routing_rule
      name="JP_Names"
      action="proxy"
      remote_dns="true"
      transports="all"
      disabled="false"
      >
      <proxy_or_chain name="Proxy_JP" />
      <hostnames>
        <hostname wildcard="*.nicovideo.jp" />
        <hostname wildcard="*.dmm.com" />
      </hostnames>
    </routing_rule>
    <routing_rule
      name="Lib_Names"
      action="proxy"
      remote_dns="true"
      transports="all"
      disabled="false"
      >
      <proxy_or_chain name="Proxy_HFUT" />
      <hostnames>
        <hostname wildcard="*.cnki.net" />
        <hostname wildcard="*.wanfangdata.com.cn" />
        <hostname wildcard="*.cqvip.com" />
        <hostname wildcard="*.ieee.org" />
        <hostname wildcard="*.webofknowledge.com" />
        <hostname wildcard="*.dl.acm.org" />
        <hostname wildcard="*.engineeringvillage.com" />
        <hostname wildcard="*.sciencedirect.com" />
        <hostname wildcard="*.theiet.org" />
      </hostnames>
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
      name="Chn_Names"
      action="direct"
      remote_dns="false"
      transports="all"
      disabled="false"
      >
      <hostnames>
EOF
cat $TMP_DIR/Chn_Names.txt | sed "s/^/        <hostname wildcard=\"*./g" | sed "s/$/\" \/>/g" | sort | awk '{if ($0!=line) print;line=$0}' >> $OUT_TMP_FILE

cat >> $OUT_TMP_FILE <<EOF
      </hostnames>
    </routing_rule>
    <routing_rule
      name="Others"
      action="proxy"
      remote_dns="true"
      transports="all"
      disabled="false"
      >
      <proxy_or_chain name="Proxy_US" />
    </routing_rule>
  </routing_rules>
  <remote_dns_exceptions>
    <remote_dns_exception wildcard="localhost" />
    <remote_dns_exception wildcard="ubuntu_server" />
    <remote_dns_exception wildcard="openwrt" />
    <remote_dns_exception wildcard="wrt32x" />
    <remote_dns_exception wildcard="freakinyy-tft5" />
    <remote_dns_exception wildcard="freakinyy-cui8" />
    <remote_dns_exception wildcard="*.localhost" />
    <remote_dns_exception wildcard="*.ubuntu_server" />
    <remote_dns_exception wildcard="*.openwrt" />
    <remote_dns_exception wildcard="*.wrt32x" />
    <remote_dns_exception wildcard="*.freakinyy-tft5" />
    <remote_dns_exception wildcard="*.freakinyy-cui8" />
EOF
cat $TMP_DIR/Chn_Names.txt | sed "s/^/    <remote_dns_exception wildcard=\"*./g" | sed "s/$/\" \/>/g" | sort | awk '{if ($0!=line) print;line=$0}' >> $OUT_TMP_FILE

cat >> $OUT_TMP_FILE <<EOF
  </remote_dns_exceptions>
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
