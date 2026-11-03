# Rspamd

Rspamd mail-filtering service image with the portfolio's local configuration
and custom maps/modules. It is based on
[`ghcr.io/nforceroh/alpine-base:3.24`](https://github.com/nforceroh/alpine-base)
and uses s6-overlay to configure and run Rspamd.

## Services and ports

| Port | Protocol | Purpose |
| --- | --- | --- |
| `11332` | TCP | Milter worker |
| `11333` | TCP | Normal worker |
| `11334` | TCP | Controller and web interface |

The image exposes `/var/lib/rspamd` as a volume for Rspamd state. Configuration
assets are copied from `/assets/rspamd` into `/etc/rspamd` during startup.

## Dependencies

The runtime configuration expects Redis, and configures ClamAV and DCC
endpoints by default. Keep these services and Rspamd on a private mail
network. Optional integrations include MailGallows metadata export and an
OpenAI-compatible GPT endpoint.

## Configuration

The following variables are declared by the Dockerfile:

| Variable | Image default | Description |
| --- | --- | --- |
| `ENABLE_SMTP` | `false` | Declared value; no bundled base-image or Rspamd startup code consumes it |
| `ADMIN_PASS` | bundled value | Controller password used to configure the worker controller; override at runtime and do not rely on the image default |
| `REDIS_HOST` | `redis-master.databases.svc.cluster.local` | Redis host |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_DB` | `7` | Redis database index |
| `REDIS_TIMEOUT` | `15s` | Redis timeout |
| `CLAMAV_HOST` | `clamav.mail.svc.cluster.local` | ClamAV host |
| `CLAMAV_PORT` | `3310` | ClamAV port |
| `LOG_LEVEL` | `info` | Rspamd log level |
| `DEBUG_MODE` | `false` | Set to `true` to start Rspamd with debug logging |

The startup script also supports the following optional settings (defaults
shown are supplied by the script when unset):

| Variable | Script default | Description |
| --- | --- | --- |
| `DCC_HOST`, `DCC_PORT` | `dcc-svc`, `10045` | DCC service endpoint |
| `MAILGALLOWS_HOST`, `MAILGALLOWS_PORT` | unset | When both are set, generate a MailGallows metadata-exporter endpoint |
| `DEBUG_MODULES` | `gpt,,metadata_exporter` | Comma-separated Rspamd debug modules |
| `GPT_ENABLED` | `false` | Enable the configured GPT module |
| `GPT_URL` | `http://ollama:11434/v1/chat/completions` | GPT-compatible API URL |
| `GPT_MODELS` | `qwen2.5:7b,gemma3:4b` | Comma-separated model names |
| `NFORCER_MULTIMAP_URL` | bundled remote map URL | URL to refresh `_multimap_nforcer.conf`; set empty to skip downloading |
| `RSPAMD_DNS_SERVERS` | unset | Optional custom DNS nameserver list |

Set the controller password and deployment-specific service hosts with runtime
configuration. Review the bundled Rspamd maps and modules before using the
image in a production mail flow.

## Usage

Connect Rspamd to Postfix and its Redis, ClamAV, and (if enabled) DCC services
on a private network. Persist Rspamd state:

```sh
docker run -d --name rspamd \
  --restart unless-stopped \
  --network mail \
  -p 11332:11332 -p 11333:11333 -p 11334:11334 \
  -v rspamd-data:/var/lib/rspamd \
  -e ADMIN_PASS='replace-with-a-secret' \
  -e REDIS_HOST=redis \
  -e REDIS_PORT=6379 \
  -e REDIS_DB=7 \
  -e CLAMAV_HOST=clamav \
  -e CLAMAV_PORT=3310 \
  -e DCC_HOST=dcc \
  -e DCC_PORT=10045 \
  ghcr.io/nforceroh/rspamd:latest
```

The controller/web interface on port `11334` should not be exposed directly
to the public Internet. Configure Postfix's milter endpoint to use the
appropriate Rspamd worker service and port for your mail flow.

## Learning messages

Use `rspamc learn_spam` and `rspamc learn_ham` from a trusted client configured
to authenticate to this Rspamd controller. For example, to learn a local
message file:

```sh
rspamc learn_spam < spam-message.eml
rspamc learn_ham < ham-message.eml
```

The repository also contains `cleanup-german-maps.sh` for map maintenance;
review that script and the upstream map sources before running it.

## Local development

```sh
make build   # build ghcr.io/nforceroh/rspamd:dev
make test    # build and run the s6/boot smoke tests
make run     # publish ports 11332, 11333, and 11334
```

The local run target does not create Redis, ClamAV, or DCC dependencies.
Configure reachable endpoints before using Rspamd for mail filtering. CI
publishes through [`nforceroh/.github`](https://github.com/nforceroh/.github).
