# shell-roboshop

Bash scripts that install the RoboShop microservice stack on RHEL/Amazon Linux hosts. Same components as `ansible-roboshop`, without Ansible — useful for understanding the raw install path before moving to config management.

## Fixes included in this revision

- Logging was broken: redirects used `&>>LOG_FILE` (literal filename) instead of `&>>"$LOG_FILE"`
- Systemd units contained documentation junk (`// highlight-start`) which systemd rejects
- Frontend `nginx.conf` pointed `/api/payment/` at the shipping host IP — corrected
- Hardcoded VPC IPs moved to `config.env` + `/etc/roboshop/*.env` (mode `0600`)
- Shared helpers in `common.sh` (root check, VALIDATE, env file writer)
- Plaintext passwords no longer live in unit files

## Quick start

```bash
cp config.env.example config.env
# edit DOMAIN_NAME, hostnames / IPs, AMI_ID, SG_ID, ZONE_ID, passwords

# On the control machine — launch instances + DNS
./roboshop.sh mongodb redis mysql rabbitmq catalogue user cart shipping payment frontend

# On each instance (as root), run the matching script from a clone of this repo
sudo ./mongodb.sh
sudo ./redis.sh
sudo ./mysql.sh
sudo ./rabbitmq.sh
sudo ./catalogue.sh
sudo ./user.sh
sudo ./cart.sh
sudo ./shipping.sh
sudo ./payment.sh
sudo ./frontend.sh
```

Recommended order matches the list above: data tier → app tier → frontend.

## Configuration

| File | Purpose |
| --- | --- |
| `config.env.example` | Template — copy to `config.env` (gitignored) |
| `common.sh` | Sourced by every component script |
| `/etc/roboshop/<svc>.env` | Written at install time; referenced by systemd `EnvironmentFile=` |
| `*.service` | Systemd units — no secrets embedded |

Hostnames default to `<component>.roboshop.internal`. Point Route53 (or `/etc/hosts`) there, or set plain IPs in `config.env`.

## Layout

```
roboshop.sh          EC2 + Route53 bootstrap
mongodb.sh redis.sh mysql.sh rabbitmq.sh
catalogue.sh user.sh cart.sh shipping.sh payment.sh
frontend.sh nginx.conf
common.sh config.env.example
*.service
```

## License

MIT — see [LICENSE](LICENSE).
