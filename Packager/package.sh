#!/bin/bash

if [ -f BSTestLib.zip ] ; then
    rm BSTestLib.zip
fi
zip -r BSTestLib.zip manifest source components -x *.gitignore

curl --user "rokudev:youi" --digest -v -S -F "mysubmit=Install" -F "archive=@BSTestLib.zip" -F "passwd=" http://"$1"/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"

#wget --user rokudev --password youi -F "app_name=BSTestLib" -F "passwd=CccchAmCIYZJHtbL4KH/Vg==" http://"$1"/plugin_package

curl -d --user "rokudev:youi" --digest -v -S -F "app_name=BSTestLib" -F "passwd=CccchAmCIYZJHtbL4KH/Vg==" http://"$1"/plugin_package

#curl --user "rokudev:youi" --digest -v -S -F "app_name=BSTestLib" -F "passwd=CccchAmCIYZJHtbL4KH/Vg==" http://"$1"/plugin_package
