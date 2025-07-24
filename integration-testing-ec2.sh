#!/bin/bash

echo "Integration test..."

aws --version

Data=$(aws ec2 describe-instances)
echo "Data: $Data"

# Get the Public DNS of the instance with tag value 'dev_deploy'
URL=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "dev_deploy") | .PublicDnsName')
echo "URL Data: $URL"

if [[ -n "$URL" ]]; then
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$URL:3000/live)
    echo "http_code: $http_code"

    planet_data=$(curl -s -X POST http://$URL:3000/planet -H "Content-Type: application/json" -d '{"id": "3"}')
    echo "planet_data: $planet_data"

    planet_name=$(echo "$planet_data" | jq -r '.name')
    echo "planet_name: $planet_name"

    if [[ "$http_code" -eq 200 && "$planet_name" == "Earth" ]]; then
        echo "HTTP Status Code and Planet Name Tests Passed"
    else
        echo "One or more test(s) failed"
        exit 1
    fi
else
    echo "Could not fetch a token/URL; Check/Debug line 6"
    exit 1
fi
