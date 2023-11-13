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