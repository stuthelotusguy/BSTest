#!/bin/bash

if [ -f "$1".zip ] ; then
    rm "$1".zip
fi
zip -r "$1".zip manifest source components -x *.gitignore

curl --user "rokudev:youi" --digest -v -S -F "mysubmit=Install" -F "archive=@"$1".zip" -F "passwd=" http://"$2"/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"

#wget --user rokudev --password youi -F "app_name="$1"" -F "passwd=CccchAmCIYZJHtbL4KH/Vg==" http://"$2"/plugin_package

curl -d --user "rokudev:youi" --digest -v -S -F "app_name="$1"" -F "passwd=CccchAmCIYZJHtbL4KH/Vg==" http://"$2"/plugin_package > text.txt

#curl --user "rokudev:youi" --digest -v -S -F "app_name="$1"" -F "passwd=CccchAmCIYZJHtbL4KH/Vg==" http://"$2"/plugin_package > text.txt
