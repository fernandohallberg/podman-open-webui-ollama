#!/bin/bash

cd $(dirname $(realpath $0))

set -e

PODNAME=open-webui
APP_NAME=${PODNAME}

stop() {
        if podman pod exists ${PODNAME}; then
                echo ": identificado pod existente ${PODNAME}"
                echo ": parando pod ${PODNAME}"
                podman pod stop -t 60 ${PODNAME}
                ERR=$?
                if [ $ERR -gt 0 ]; then
                        echo "ERRO $ERR parando POD ${PODNAME}"
                        exit $ERR
                fi
                echo ": removendo pod ${PODNAME}"
                podman pod rm ${PODNAME}
                ERR=$?
                if [ $ERR -gt 0 ]; then
                        echo "ERRO $ERR removendo POD ${PODNAME}"
                        exit $ERR
                fi
        fi
}

start() {

stop

podman pod create --name ${PODNAME} -p 8080:8080 -p 11434:11434

mkdir -p ./ollama
mkdir -p ./data

podman run -d --gpus=all --pod=${PODNAME} -v ./ollama:/root/.ollama --name ${PODNAME}-ollama --pull=newer --restart always docker.io/ollama/ollama
podman run -d --gpus=all --pod=${PODNAME} -v ./data:/app/backend/data --name ${PODNAME}-app --pull=newer --restart always \
        -e OLLAMA_BASE_URL=http://${PODNAME}:11434 \
        ghcr.io/open-webui/open-webui:main
}

case $1 in
        'start')
                start
                ;;
        'stop')
                stop
                ;;
        *)
                echo "uso: $0 [stop|start]"
                ;;
esac
