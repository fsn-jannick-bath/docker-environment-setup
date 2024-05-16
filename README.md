# Docker Environment Setup

## Getting Started

```bash
git clone https://gitlab.lupcom.de/jbath/docker-environment-setup.git .
chmod u+x install.sh
sudo ./install.sh
```

## Adding a new domain

Add domain to `/etc/hosts`

```txt
127.0.0.1      new-domain.loc
```

Add domain to domains.txt

```txt
yourdomain.de example.loc ... [new domain]
```

Update certificates.

```bash
mkcert -key-file ./certs/key.pem -cert-file ./certs/cert.pem $(cat certs/domains.txt)
```

Restart environment.

```bash
docker-compose down && docker-compose up -d
```

## Traefik & Docker compose

Example `docker-compose.yml` for http traffic.

```yaml
version: "3"
services:
  traefik:
    image: "traefik:v2.9"
    container_name: "traefik"
    restart: "always"
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=traefik_net"
      #- "--providers.file.filename=/root/.config/ssl.toml"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.address=:80"
      - "--log.level=DEBUG"
    ports:
      - "443:443"
      - "80:80"
      - "9090:8080"
    volumes:
      #- "./certs:/certs"
      #- ./traefik-ssl.toml:/root/.config/ssl.toml
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    labels:
      - traefik.enable=true
      #- traefik.http.middlewares.whoami-https.redirectscheme.scheme=https
      - traefik.http.routers.traefik-http.entrypoints=web
      - traefik.http.routers.traefik-http.rule=Host(`traefik.ipv6.aeef.tech`)
      #- traefik.http.routers.whoami-http.middlewares=whoami-https@docker
      #- traefik.http.routers.whoami.entrypoints=web-secure
      #- traefik.http.routers.whoami.rule=Host(`whoami.example.com`)
      #- traefik.http.routers.whoami.tls=true
      #- traefik.http.routers.whoami.tls.certresolver=certificatesResolverDefault
      - traefik.docker.network=traefik_net
      - traefik.http.services.traefik-http.loadbalancer.server.port=8080
      
    networks:
      - traefik_net
      
networks:
  traefik_net:
    external: true
```

### Ports

```yaml
ports:
  # - [PortOnHost]:[PortInTheContainer]
    - "80:80"
    - "9090:8080"
  # - [PortInTheContainer] -> Port for the host is automatically assigned to a random port like 55678
    - 8080
```

### Traefik Labels

Loadbalancer:

```yaml
labels:
  # - traefik.http.services.[httpServiceName].loadbalancer.server.port=[portInTheContainer]
    - traefik.http.services.traefik-http.loadbalancer.server.port=8080
```

Host:

```yaml
labels:
  # - traefik.http.routers.[httpServiceName].rule=Host(`[ipOrDomain*]`)
    - traefik.http.routers.traefik-http.rule=Host(`traefik.ipv6.aeef.tech`)
```

\* = An ip (or domain) that points to traefik. For example `*.example.com` points to 212.172.142.22. Traefik can only direct traffic if all the sub-domains that should be resolved point to it's service, in this case the traefik service listens on 212.172.142.22 on port :80 and :443.

You could also make traefik listen on, lets say, port :8080. Then you would have to pass that port every time you try to access a sub-domain directed by traefik. In this case `sub.example.com:8080`.

The host entry is **mandatory** in order to use traefik's service.

### Docker Networks

"Import" a network into a stack. If multiple containers share the same network, they can access all the internal ports of each other. However note that if you try to access a port of another container, it's only accessible under the container name (not localhost). 

**Example**:
<br>
The **smtp-container** has a published port **2525->25**.
<br>
An **example-container** has the published port **8080->80**.
<br>
They both share the network **"smtp-network"**.

```bash
# Access port 80 from example-container
$ telnet localhost 80
```

```bash
# Access port 25 from example-container
$ telnet smtp-container 25
```

The host name is always the exact same as the container name.

```yaml
# networks:
#   [nameOfNetwork]:
#     external: true

networks:
  traefik_net:
    external: true
```

```yaml
# services:
#   [nameOfService]:
#      networks:
#         - [nameOfNetwork]

services:
  traefik:
    networks:
      - traefik_net
```

### Local networks

Traefik as an external network to allow routing. Define redis and mariadb as local networks. If the local network is not provided the containers can't communicate with eachother, whilst also running traefik.

```yaml
version: "3"
services:
  owncloud:
    networks:
      - redis
      - mariadb
      - traefik_net

  mariadb:
    networks:
      - mariadb

  redis:
    networks:
      - redis
      
networks:
  traefik_net:
    external: true
  redis:
    external: false
  mariadb:
    external: false
```
## Further Information

If you try to reference a (named) docker volume or network, that has been created outside of the docker-compose.yml itself, you have to "import" it by specifying it as "external".

For volumes:

```yml
# volumes:
#   [name of volume]:
#     external: true

volumes:
  portainer_data:
    external: true
```

For networks:

```yml
# networks:
#   [name of network]:
#     external: true

networks:
  traefik_net:
    external: true
```

A docker network can be created like this:

```bash
docker network create (-d bridge) my-network
```

A docker volume can be created like this:

```bash
docker volume create my-volume
```
