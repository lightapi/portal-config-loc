# Validate The NVIDIA Embedding Alias

Use these commands after publishing the LLM configuration and confirming that
the target `light-gateway` replica has applied it. They exercise the ordinary
gateway data plane; they do not send the NVIDIA API key from this client.

Prerequisites:

- `curl` and `jq`;
- an authorized gateway client bearer token;
- the expected embedding-space ID and revision from the publication; and
- `config/ca.pem` for the local HTTPS certificate.

Run from `portal-config-loc/all-in-lt/llm-gateway-rust`.

For the checked automation helper and the independent `kb-query`/`kb-index`
NVIDIA demo lanes, use [`NVIDIA-DEMO.md`](NVIDIA-DEMO.md).

## Prepare protected files

```bash
set -euo pipefail
umask 077

gateway_url=https://localhost:8444
model_alias=kb-query
expected_space_id=nvidia-nemotron-3-embed-1b
expected_space_revision=1

gateway_header_file=$(mktemp)
embedding_request_file=$(mktemp)
response_headers_file=$(mktemp)
safe_headers_file=$(mktemp)
trap 'rm -f -- "$gateway_header_file" "$embedding_request_file" "$response_headers_file" "$safe_headers_file"' EXIT

read -rsp 'Gateway client bearer token: ' gateway_client_token
printf '\n'
printf 'Authorization: Bearer %s\n' "$gateway_client_token" >"$gateway_header_file"
unset gateway_client_token
chmod 600 "$gateway_header_file"

jq -n \
  --arg model "$model_alias" \
  --arg text 'light-gateway configuration validation' \
  '{model:$model,input:$text}' >"$embedding_request_file"
chmod 600 "$embedding_request_file"
```

The token is read without terminal echo. Curl receives only the protected file
path in its process arguments.

## Confirm the Alias is visible

```bash
curl \
  --silent \
  --show-error \
  --fail-with-body \
  --proto '=https' \
  --tlsv1.2 \
  --connect-timeout 5 \
  --max-time 30 \
  --max-redirs 0 \
  --cacert config/ca.pem \
  --header "@$gateway_header_file" \
  "$gateway_url/v1/models/$model_alias" |
jq -e --arg model "$model_alias" '
  .id == $model and
  .object == "model" and
  .owned_by == "light-gateway"
'
```

Alias discovery is gateway-local and must not call NVIDIA.

## Validate one embedding

```bash
curl \
  --silent \
  --show-error \
  --fail-with-body \
  --proto '=https' \
  --tlsv1.2 \
  --connect-timeout 5 \
  --max-time 30 \
  --max-redirs 0 \
  --cacert config/ca.pem \
  --request POST \
  --header "@$gateway_header_file" \
  --header 'content-type: application/json' \
  --header "X-Light-Expected-Embedding-Space-Id: $expected_space_id" \
  --header "X-Light-Expected-Embedding-Space-Revision: $expected_space_revision" \
  --data-binary "@$embedding_request_file" \
  --dump-header "$response_headers_file" \
  "$gateway_url/v1/embeddings" |
jq -e -f validation/embedding-summary-v1.jq
```

Expected output:

```json
{
  "status": "pass",
  "model": "kb-query",
  "vectorCount": 1,
  "dimension": 2048,
  "promptTokens": 5,
  "totalTokens": 5
}
```

Token counts can differ. The filter validates them as numbers but never prints
the embedding values.

## Validate and retain safe response metadata

```bash
header_value() {
  local header_name=$1
  awk -v expected="$header_name" '
    {
      sub(/\r$/, "")
      name = $0
      sub(/:.*/, "", name)
      if (tolower(name) == tolower(expected)) {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)
      }
    }
    END {
      if (value == "") exit 1
      print value
    }
  ' "$response_headers_file"
}

request_id=$(header_value x-request-id)
actual_space_id=$(header_value x-light-embedding-space-id)
actual_space_revision=$(header_value x-light-embedding-space-revision)
config_generation=$(header_value x-light-config-generation)
billed_cost_micros=$(header_value x-light-billed-cost-micros)

test "$actual_space_id" = "$expected_space_id"
test "$actual_space_revision" = "$expected_space_revision"
[[ $config_generation =~ ^[1-9][0-9]*$ ]]
[[ $billed_cost_micros =~ ^[0-9]+$ ]]
test -n "$request_id"

jq -n \
  --arg requestId "$request_id" \
  --arg embeddingSpaceId "$actual_space_id" \
  --argjson embeddingSpaceRevision "$actual_space_revision" \
  --argjson configGeneration "$config_generation" \
  --argjson billedCostMicros "$billed_cost_micros" \
  '{requestId:$requestId,embeddingSpaceId:$embeddingSpaceId,embeddingSpaceRevision:$embeddingSpaceRevision,configGeneration:$configGeneration,billedCostMicros:$billedCostMicros}' \
  >"$safe_headers_file"

chmod 600 "$safe_headers_file"
jq -e . "$safe_headers_file"
```

Keep only the bounded summary and safe metadata when evidence is required.
Delete the raw response-header file after the assertions.

## Production TLS

For a gateway certificate issued by a publicly trusted CA, use the same
commands but omit the private-CA argument; curl then uses the system trust
store. Do not disable certificate verification or enable redirect following.

## Interpreting failures

The body contains the gateway's bounded public error envelope. Use its code and
`x-request-id` to investigate gateway logs. Do not copy a model-provider
response body, gateway bearer token, request file, or raw embedding into a
ticket or evidence record.
