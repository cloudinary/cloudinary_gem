# Configure Cloudinary

## When to use

Do this once per process before any upload, admin, or URL-generation call.

**Prerequisite:** a `cloud_name`, `api_key`, and `api_secret`. If you do not have them,
see [Get Cloudinary credentials](get-credentials.md) — `npx @cloudinary/cloud` provisions
a working cloud with no signup.

## Recommended: environment variable

Set `CLOUDINARY_URL` (from Console > Settings > API Keys, or written into `.env` for you
by `npx @cloudinary/cloud`):

```bash
export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
```

```ruby
require "cloudinary"
# Configuration is read from CLOUDINARY_URL automatically on first use.
puts Cloudinary.config.cloud_name
```

## Alternative: explicit configuration

```ruby
require "cloudinary"

Cloudinary.config do |config|
  config.cloud_name = "my-cloud"
  config.api_key    = ENV["CLOUDINARY_API_KEY"]
  config.api_secret = ENV["CLOUDINARY_API_SECRET"]
  config.secure     = true
end
```

`Cloudinary.config(hash)` sets the same values from a hash.

## Alternative: config/cloudinary.yml (Rails)

Rails apps can keep settings in `config/cloudinary.yml`, keyed by environment. See
[Use with Rails](use-with-rails.md) — including why credentials belong in
`CLOUDINARY_URL` or Rails encrypted credentials rather than in that file.

## Precedence

Verified against this version, highest priority first:

1. **Per-call options** — any option passed to a method overrides config for that call.
2. `Cloudinary.config` assignments made at runtime.
3. **Discrete `CLOUDINARY_*` environment variables** (`CLOUDINARY_CLOUD_NAME`,
   `CLOUDINARY_API_KEY`, ...).
4. `CLOUDINARY_URL`.
5. `config/cloudinary.yml`, section matching `CLOUDINARY_ENV` or `Rails.env`.

> **Trap:** if `CLOUDINARY_CLOUD_NAME` is set, `CLOUDINARY_URL` is ignored **completely**
> — not merged. The SDK then takes every other value from the discrete variables or the
> YAML file, so a stale `api_key` can survive while `cloud_name` looks correct. Use one
> mechanism or the other, not both.

## Behavior you should know

- Configuration is **process-global**: `Cloudinary.config` affects every caller in the
  process. Pass per-call options as the trailing hash when you need to override one call.
- **Delivery URLs are HTTPS by default** in this SDK; you do not need `secure: true`.
  Pass `secure: false` to get an `http://` URL.
- Generated URLs carry an `?_a=` SDK-analytics parameter. It does not affect delivery or
  caching. Disable per call with `analytics: false`.
- Account-level (provisioning) operations read `CLOUDINARY_ACCOUNT_URL` through
  `Cloudinary.account_config`.
- Proxy support: set `api_proxy` in config.

## Validate configuration early

```ruby
%w[cloud_name api_key api_secret].each do |key|
  raise "Cloudinary is not configured: set CLOUDINARY_URL (missing #{key})" if Cloudinary.config.send(key).nil?
end
```

## Troubleshooting

- `Must supply cloud_name` / `Must supply api_key` — `CLOUDINARY_URL` is missing or
  malformed; it must start with `cloudinary://`. Note the exception class differs by
  entry point; see [Troubleshoot errors](troubleshoot-errors.md).
- `Invalid Signature` on uploads — a wrong `api_secret`. Uploads report it this way
  instead of naming the secret.
- Config silently empty in a Rails app — the `cloudinary.yml` section name must match
  `Rails.env`; a file with only a `development:` key gives nothing under `test`.

## Related

- [Get Cloudinary credentials](get-credentials.md) — if you do not have an account yet.
- [Sign a browser upload](sign-browser-upload.md) — keeping the secret server-side.
- [Use with Rails](use-with-rails.md)
