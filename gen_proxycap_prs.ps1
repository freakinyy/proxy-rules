echo "Generating XML file..."
.\gen_proxycap_xml.sh -o  .\default.xml
echo "Generating PRS file..."
.\xml2prs.exe .\default.xml .\default.prs
echo "Updating to Git..."
git commit -a -m '' --allow-empty-message
git push