#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pidFile=${DIR}/WebGL-Pixi.pid
logFile=${DIR}/WebGL-Pixi.log


if [ -f "${pidFile}" ]; then
    echo "WebGL-Pixi is already running"
else
    message="WebGL-Pixi Service Started on $(date)"
    echo -e ${message}
    echo -e "\n\n"${message} >> ${logFile}
    DEBUG=BSServer:* nohup node ${DIR}/bin/www >> ${logFile} 2>&1 & echo $! > ${pidFile}
fi
