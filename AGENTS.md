# AGENTS.md — cloudinary_gem

## What this package is (one line)
Official Cloudinary Ruby/Rails server SDK: upload assets, build transformation and delivery URLs/tags, call the Admin API, and wire Cloudinary into Active Storage or CarrierWave — all from a backend where the `api_secret` stays private.

## When to use this / when NOT to use this
- **Use this when:** you are in a Ruby or Rails server runtime (Rails app, Sinatra service, background job, plain script) and need signed uploads, asset administration, view tags (`cl_image_tag`, `cl_video_tag`), or signed delivery URLs.
- **Do NOT use this when:** you need browser-side delivery URLs in a JS frontend — use [`@cloudinary/url-gen`](https://github.com/cloudinary/js-url-gen), which builds URLs without exposing a secret. For a no-code/autonomous agent path, use the [Cloudinary MCP server](https://github.com/cloudinary/mcp-servers).
- **Sibling packages:** `@cloudinary/url-gen` = browser URL builder; [`attachinary`](https://github.com/cloudinary/attachinary) = legacy Rails attachment gem (prefer Active Storage for new apps). Stay on this gem's `1.x` line only for Ruby 1.9.3/2.x.

## Setup
```bash
gem install cloudinary          # or add `gem "cloudinary"` to your Gemfile, then: bundle install
```
Required configuration / credentials — the SDK reads `CLOUDINARY_URL` automatically:
```bash
export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
```

## Minimal runnable example
```ruby
require 'cloudinary'   # CLOUDINARY_URL is picked up from the environment

# Upload a local file from the server (uses the api_secret — server-side only)
result = Cloudinary::Uploader.upload("my_picture.jpg")
puts result["public_id"]

# Build a 100x150 fill-crop delivery URL for an uploaded asset
puts Cloudinary::Utils.cloudinary_url("sample.jpg", width: 100, height: 150, crop: "fill")
```
In Rails views, prefer the `cl_image_tag("sample.jpg", width: 100, height: 150, crop: "fill")` helper.

## Build / test commands (run these after editing)
```bash
bundle install                         # install gem + dev dependencies
export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
bundle exec rspec --format documentation --color   # full suite (exactly what CI runs)
bundle exec rspec -f d                 # shorthand the project's CONTRIBUTING uses
bundle exec rspec spec/uploader_spec.rb   # a single spec file
```
- No linter is configured (no `.rubocop.yml`, no rubocop in `cloudinary.gemspec`). Do not invent a `lint` task.
- `rake` / `rake spec` is the default Rake task and also runs the suite. `rake build` first runs `cloudinary:fetch_assets`.

## Conventions & gotchas
- **The test suite hits the live Cloudinary API.** Specs require a real `CLOUDINARY_URL` and a network connection — they are not fully hermetic. Use a throwaway/test cloud; some specs create and delete real assets. `rspec-retry` is enabled for flaky network specs.
- **Code must work both with and without Rails.** Rails-specific code lives in `lib/cloudinary/helper.rb`, `engine.rb`, `railtie.rb`, and `lib/active_storage/service/cloudinary_service.rb`; core API code (`uploader.rb`, `api.rb`, `utils.rb`, `search.rb`) must load in plain Ruby too.
- Source lives under `lib/cloudinary/`; the version is in `lib/cloudinary/version.rb`. Bump it there, not in the gemspec.
- HTTP goes through Faraday (`faraday`, `faraday-multipart`, `faraday-follow_redirects`) — keep new request code on that stack.
- **Never expose `api_secret` to a browser.** Signed uploads and signed URLs are exactly why this gem is server-side; do not port that logic to a frontend bundle.
- **Supported versions (2.x):** Ruby `>= 3, < 5`; Rails 6/7/8. CI matrix runs Ruby 3.1.7, 3.2.9, 3.3.10, 3.4.8, and 4.0.0.

## Canonical docs (leave the repo for depth)
- Ruby on Rails SDK guide: https://cloudinary.com/documentation/rails_integration
- Transformation & REST API reference: https://cloudinary.com/documentation/cloudinary_references
- MCP server (agent/no-code path): https://github.com/cloudinary/mcp-servers

## Agent / MCP note
If this capability is also exposed via the Cloudinary MCP servers, prefer the MCP tool for autonomous task execution and use this SDK for code generation. See cloudinary/mcp-servers.

## Commit / PR conventions
- Default branch is `master`; branch from it and open a PR against it (CI runs on pushes/PRs to `master`).
- Provide test code covering new behavior, and make sure it works **both with and without Rails** (per `CONTRIBUTING.md`).
- PR description must clearly state the bug/feature and reference the relevant issue number when applicable. The CI check "Ruby Test 💎" must pass across the Ruby matrix.
