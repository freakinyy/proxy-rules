echo "生成xml文件..."
.\gen_proxycap_xml.sh -o  .\default.xml
echo "生成prs文件..."
.\xml2prs.exe .\default.xml .\default.prs
git commit -a -m '' --allow-empty-message
git push