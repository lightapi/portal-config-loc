# CLI device sign-in (local dev stack)

`/login` in the Light CLI signs a user in with the standard OAuth device authorization grant
(RFC 8628) served by `light-oauth`. Design:
`light-portal-doc/src/design/light-oauth/device-authorization.md`.

Nothing here is a deployment of its own: `light-oauth` serves it on its one port, the image is
built like every other (`portal-service/build.sh <tag> -s light-oauth -l`), and
`portal-config-loc/scripts/deploy-local.sh lt` starts it with the one `docker-compose.yml`.

## What to set up, once

1. **Database.** Apply `portal-db/postgres/patch_20260921_device_authorization.sql`. It is one patch,
   safe to apply again, and it also upgrades a database that has the earlier certificate-bound draft.
2. **The client**, from Portal's UI like every other control-plane change (UI, then command, then
   event; never a direct write to the database). A device client is an ordinary client with
   **Client Profile `cli`** and **Client Type `public` or `trusted`**, scope `portal.r portal.w`, and
   linked to the provider (Provider Client). The existing "Light CLI" client, which is `trusted` and
   is what the CLI's application token was issued from, only needs its **profile** changed to `cli`:
   it keeps its secret and everything that needs it. Its id is `cli.oauthClientId` in
   `light-fabric/apps/light-cli/config/cli.yml`. The device flow never uses the secret: a request
   that presents one takes the ordinary path, where it is checked.
3. **Settings** (all optional) are the `device_*` keys in `light-oauth-rust/config/values.yml`:
   login length (`device_session_seconds`, default one day), the "remember me" length
   (`device_remember_seconds`, default 90 days), and the page the user opens
   (`device_verification_uri`, portal-view's `/device`).
4. **portal-view** needs nothing but the `/device` page: the provider comes from the link the CLI prints
   (`light-oauth` adds `?provider=`). `device_verification_uri` must be portal-view's own address
   (`https://localhost:3000/device` for the dev server), not the Gateway's: the Gateway does not serve
   the page.
5. **light-gateway** (Portal snapshot): routes to light-oauth for `POST /oauth2/*/device_authorization`,
   `POST /oauth2/*/token`, `POST /oauth2/*/revoke` (from the CLI, no user token needed), and
   `GET /oauth2/*/device/lookup`, `POST /oauth2/*/device/approve` (from portal-view, with the
   session as a bearer). Rate limit all of them by address, overwrite `X-Forwarded-For`, and do
   not publish light-oauth's port on the host in a real deployment.

## Trying it

```sh
cd light-fabric/apps/light-cli
./start-cli.sh                # opens the Light CLI terminal; it stays open until /exit
# then, inside it:
#   /login     prints a code and an address; approve it on the portal-view page
#   /whoami    who is signed in, and when the login ends
```

The CLI's defaults (`cli.oauthUri`, `cli.oauthProviderId`, `cli.oauthClientId` in
`light-fabric/apps/light-cli/config/cli.yml`) match this stack: `https://localhost` is the Gateway.
