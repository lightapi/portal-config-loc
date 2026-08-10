def invalid($message): error($message);

if .object != "list" then invalid("unexpected response object")
elif (.data | type) != "array" or (.data | length) != 1 then
  invalid("expected exactly one embedding")
elif (.data[0].embedding | type) != "array" then
  invalid("embedding is not an array")
elif (.data[0].embedding | length) != 2048 then
  invalid("unexpected embedding dimension")
elif (.model | type) != "string" or .model != "kb-query" then
  invalid("unexpected model alias")
elif (.usage.prompt_tokens | type) != "number" then
  invalid("prompt token count is missing")
elif (.usage.total_tokens | type) != "number" then
  invalid("total token count is missing")
else {
  status: "pass",
  model: .model,
  vectorCount: (.data | length),
  dimension: (.data[0].embedding | length),
  promptTokens: .usage.prompt_tokens,
  totalTokens: .usage.total_tokens
}
end
