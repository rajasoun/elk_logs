#!/usr/bin/env bash

set -eo pipefail

COMPOSE_FILES=" -f elk.yml -f filebeat.yml"

function help(){
    echo "Usage: $0  {up|down|status|logs}" >&2
    echo
    echo "   up               Provision, Configure, Validate Application Stack"
    echo "   down             Destroy Application Stack"
    echo "   status           Displays Status of Application Stack"
    echo "   logs             Application Stack Logs"
    echo "   ship             Ship Logs"
    echo
    return 1
}

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    up)
      echo "Bring Up EK Application Stack"
      docker network create elk
      # docker run -d --name="elk-logs" --rm \
      #        --volume=/var/run/docker.sock:/var/run/docker.sock \
      #        --publish=127.0.0.1:8989:80 gliderlabs/logspout
      docker-compose ${COMPOSE_FILES} up -d
      docker run --rm willwill/wait-for-it "http://kibana:5601/api/status" -- echo "Kibana is Up" 
      docker run --rm willwill/wait-for-it "http://elasticsearch:9200"     -- echo "    ES is Up" 
      echo -e "Goto Kibana -> http://localhost:5601/app/kibana#/home"
      docker rm filebeat
      ;;
    down)
      echo "Destroy Application Stack & Services"
      docker-compose ${COMPOSE_FILES} down -v --remove-orphans
      docker network rm elk
      docker stop elk-logs 
      ;;
    ship)
      echo -e "\nShipping Logs..."
      docker-compose -f filebeat.yml run  -d filebeat
      ;;
    status)
      echo -e "\nContainers Status..."
      docker-compose ${COMPOSE_FILES}  ps
      ;;
    logs)
      echo "Containers Log..."
      curl http://127.0.0.1:8989/logs
      ;;
    *)  help ;;
esac