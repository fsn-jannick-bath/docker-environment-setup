#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit
fi

sed -i.bck '$s/$/ $1/' ./certs/domains.txt
sed -i '1s/^/127.0.0.1       $1\n /' /etc/hosts

mkcert -key-file ./certs/key.pem -cert-file ./certs/cert.pem $(cat ./certs/domains.txt)

docker-compose down && docker-compose up -d