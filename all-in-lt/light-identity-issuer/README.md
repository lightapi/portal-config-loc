# light-identity-issuer (local dev config)

The workload identity issuer: it signs client certificates for installs and
services. See `docs/src/design/workload-identity-issuance.md` in `light-fabric`.

> **The Light CLI no longer enrolls here.** Since 2026-09-22 the CLI is a public client that signs the
> user in and sends only the user's token, with no certificate (see `light-cli.md` in `light-fabric`).
> The issuer is for agents and runners deployed in a controlled pipeline. The `light-cli` entry in
> `config/issuer.yml` `bootstrap_roles`, and the `light-cli` token examples below, remain only as a
> sample to exercise the issuer; replace them when a real workload is registered.

## The CA key in `pki/` is a DEV-ONLY key, checked in on purpose

`pki/ca.pem` and `pki/ca.key` are the issuer's CA for the local `all-in-lt` stack
(`CN = Light Fabric Workload Issuer CA`, RSA 3072, valid until 2036-09-17). The
private key is committed, like the other dev keys in this repo, so a fresh
checkout works out of the box. **Anyone with this key can mint certificates the
local Gateway would trust once `caTrust` is enabled for it. It must never be used
outside a developer's own machine.**

Other environments (`dev.lightapi.net`, staging, production) generate their own CA
and its key is **never** checked into GitHub. Do not copy this one to them.

To regenerate it (this changes the CA digest, so any Gateway `caTrust` entry must
be updated, and every enrolled install must enroll again):

```sh
openssl req -x509 -newkey rsa:3072 -nodes -sha256 -days 3650 \
  -subj "/CN=Light Fabric Workload Issuer CA" \
  -keyout pki/ca.key -out pki/ca.pem
```

## HTTPS

`config/issuer.yml` points `tls_certificate_path` / `tls_key_path` at the shared
dev server certificate that `docker-compose.yml` mounts at `/tls` (SANs include
`localhost` and `127.0.0.1`). The issuer refuses to start without TLS settings.
Clients verify it with the dev CA in `light-gateway-rust/config/ca.pem`, which is
the `bootstrapCaCertPath` of a client that calls the issuer. That certificate does not name the
`light-identity-issuer` container, so reach the issuer as `https://localhost:9443`
from the host.

## Durable state and re-arming a token

The issuer accepts each bootstrap token once and records that in
`/data/spent-tokens.jsonl` (the named volume `light-identity-issuer-state`), so a
restart does **not** hand a used token back. It refuses to start without
`state_dir` (or an explicit `allow_ephemeral_state: true`, for a throwaway run).
`docker compose down -v` deletes the volume and re-arms every token.

```sh
./issuer-tokens.sh list             # which tokens are spent, and when
./issuer-tokens.sh reset <jti>      # let one enroll once more
```

The script stops the issuer while it reads or changes the record (the running
service locks it) and starts it again. The `jti` is a claim inside the token; for
the dev `light-cli` token it is `Tide00yxSVilY9LXNKdRqg`. Single instance only: the
lock is a local file lock, so a second issuer needs a shared store instead.

## Environments and roles

`environments` sets the leaf lifetime per env tag (`loc`, `dev`, `prod`).
`bootstrap_roles` lists which app-token service IDs may enroll and the role each
certificate carries; with none configured, every token is rejected.
