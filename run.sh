zip -r BSTest.zip images source fonts channelstore components assets* -x *.gitignore
curl --user "rokudev:youi" --digest -v -S -F "mysubmit=Install" -F "archive=@BSTest.zip" -F "passwd=" http://"$1"/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"
