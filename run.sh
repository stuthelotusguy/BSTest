#!/bin/bash

if [ -f BSTest.zip ] ; then
    rm BSTest.zip
fi
zip -r BSTest.zip manifest images source components -x *.gitignore
curl --user "rokudev:youi" --digest -v -S -F "mysubmit=Install" -F "archive=@BSTest.zip" -F "passwd=" http://"$1"/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"
