#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pidFile=${DIR}/WebGL-Pixi.pid
logFile=${DIR}/WebGL-Pixi.log

if [ -f "${pidFile}" ]; then
    kill $(<"$pidFile")
    rm -f ${pidFile}
    message="WebGL-Pixi Service Stopped on $(date)"
    echo -e ${message}
    echo -e ${message} >> ${logFile}
else
    echo "WebGL-Pixi Service is not running. If that is not the case, try 'killall node'"
fi
