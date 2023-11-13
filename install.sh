#!/bin/sh

if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit
fi

if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing..."
    apt install docker
fi

if ! command -v docker-compose &> /dev/null
then
    echo "docker-compose is not installed. Installing..."
    apt install docker-compose
fi

if ! command -v mkcert &> /dev/null
then
    echo "mkcert is not installed. Installing..."

    apt install libnss3-tools
    wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64
    mv mkcert-v1.4.3-linux-amd64 /usr/bin/mkcert
    chmod +x /usr/bin/mkcert

    mkcert -install
    mkcert -key-file ./certs/key.pem -cert-file ./certs/cert.pem $(cat ./certs/domains.txt)
fi

if systemctl is-active --quiet apache2 ; then
    systemctl stop apache2
    systemctl disable apache2
else
    echo "No apache webserver running. Skipping..."
fi

if [ ! -d "~/db_data" ]; then
    if mkdir -p ~/db_data ; then
        echo "Created directory ~/db_data"
    else
        echo "Failed to create ~/db_data. Skipping..."
    fi
else
    echo "Directory ~/db_data already exists. Skipping..."
fi

if docker network create traefik_net ; then
    echo "Created docker network 'traefik_net'"
else
    echo "Failed to create docker network 'traefik_net'. Skipping..."
fi

if docker network create db_network ; then
    echo "Created docker network 'db_network'"
else
    echo "Failed to create docker network 'db_network'. Skipping..."
fi

if docker volume create portainer_data ; then
    echo "Created docker volume 'portainer_data'"
else
    echo "Failed to create docker volume 'portainer_data'. Skipping..."
fi

docker-compose up -d

# Healthchecks

# Traefik
if curl -s --head --request GET https://traefik.loc | grep "200 OK" > /dev/null; then 
   echo "Traefik is running and available under https://traefik.loc"
else
    if curl -s --head --request GET http://traefik.loc | grep "200 OK" > /dev/null; then 
        echo "Https is not available. Traefik is accessible under http://traefik.loc"
    else
        echo "Traefik is not available."
    fi
fi

# Portainer
if curl -s --head --request GET https://portainer.loc | grep "200 OK" > /dev/null; then 
   echo "Portainer is running and available under https://portainer.loc"
else
    if curl -s --head --request GET http://portainer.loc | grep "200 OK" > /dev/null; then 
        echo "Https is not available. portainer is accessible under http://portainer.loc"
    else
        echo "Portainer is not available."
    fi
fi

# Adminer
if curl -s --head --request GET https://adminer.loc | grep "200 OK" > /dev/null; then 
   echo "Adminer is running and available under https://adminer.loc"
else
    if curl -s --head --request GET http://adminer.loc | grep "200 OK" > /dev/null; then 
        echo "Https is not available. adminer is accessible under http://adminer.loc"
    else
        echo "Adminer is not available."
    fi
fi

MysqlContainerId=$(docker ps -aqf "name=mysql" | head -n 1)
MysqlIp=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $MysqlContainerId)

if mysql --host=$MysqlIp --user=root -popwer384 ; then
    echo "MySQL Connection successfull."
else
    echo "Failed to connect to MySQL"
fi