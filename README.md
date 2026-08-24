[![CI](https://github.com/cloudinary/cloudinary_gem/actions/workflows/ci.yml/badge.svg)](https://github.com/cloudinary/cloudinary_gem/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/cloudinary.svg)](https://rubygems.org/gems/cloudinary)
[![License](https://img.shields.io/github/license/cloudinary/cloudinary_gem.svg)](LICENSE)

# Cloudinary Ruby on Rails SDK

Upload, transform, optimize, and manage images and videos with Cloudinary from Ruby and Rails — the `cloudinary` gem on RubyGems.

## Install

```bash
gem install cloudinary
```

Or add it to your `Gemfile`:

```ruby
gem "cloudinary"
```

## Quick start

Set your API environment variable (Console > Settings > API Keys):

```bash
export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
```

Upload an image and get an optimized delivery URL:

```ruby
require "cloudinary"

result = Cloudinary::Uploader.upload(
  "https://res.cloudinary.com/demo/image/upload/sample.jpg",
  public_id: "quickstart-sample"
)
puts "Uploaded: #{result['public_id']}"

# Build a 400x400 auto-cropped URL with automatic format and quality
url = Cloudinary::Utils.cloudinary_url(
  result["public_id"],
  width: 400, height: 400, crop: "fill",
  gravity: "auto", fetch_format: "auto", quality: "auto"
)
puts "Optimized URL: #{url}"
```

Save as `quickstart.rb` and run `ruby quickstart.rb`. [Create a free account](https://cloudinary.com/users/register_free) if you don't have one — or run `npx @cloudinary/cloud` to [provision one without signing up](docs/get-credentials.md).

In Rails the same URL is a view helper: `<%= cl_image_tag("quickstart-sample", width: 400, height: 400, crop: "fill") %>`.

## Common tasks

- [Get Cloudinary credentials](docs/get-credentials.md)
- [Configure Cloudinary](docs/configure-cloudinary.md)
- [Upload an image](docs/upload-image.md)
- [Upload a large video](docs/upload-large-video.md)
- [Sign a browser upload](docs/sign-browser-upload.md)
- [Transform and deliver an image](docs/transform-and-deliver-image.md)
- [Transform and deliver a video](docs/transform-and-deliver-video.md)
- [Search and manage assets](docs/search-and-manage-assets.md)
- [Moderate an upload](docs/moderate-upload.md)
- [Use structured metadata](docs/use-structured-metadata.md)
- [Troubleshoot errors](docs/troubleshoot-errors.md)

Rails integration, which ships in this gem:

- [Use with Rails](docs/use-with-rails.md) — view helpers, `cloudinary.yml`, credentials
- [Upload with Active Storage](docs/upload-with-activestorage.md)
- [Upload with CarrierWave](docs/upload-with-carrierwave.md)

Runnable versions live in [`examples/`](examples/) — each is a complete file you can run directly.

## When to use this SDK

Use this gem in **Ruby and Rails server-side code**: uploads, signed operations, asset
administration, search, moderation, delivery URL generation, and Rails view helpers.

For other jobs, better-fitting tools exist:

- Browser or frontend framework rendering: the [frontend SDKs](https://cloudinary.com/documentation/frontend_sdks) ([md](https://cloudinary.com/documentation/frontend_sdks.md)).
- Complete in-browser upload UI: [Upload Widget](https://cloudinary.com/documentation/upload_widget) ([md](https://cloudinary.com/documentation/upload_widget.md)).
- Text-to-image generation and image-to-video: [platform APIs](https://cloudinary.com/documentation/image_generation_addon) ([md](https://cloudinary.com/documentation/image_generation_addon.md)), not wrapped by this gem.
- Multi-step media workflow automation: [MediaFlows](https://cloudinary.com/documentation/mediaflows_user_guide) ([md](https://cloudinary.com/documentation/mediaflows_user_guide.md)).
- Interactive agent-driven asset operations: [Cloudinary MCP servers and Skills](https://cloudinary.com/documentation/cloudinary_llm_mcp) ([md](https://cloudinary.com/documentation/cloudinary_llm_mcp.md)).

The full capability map — plus the Skills, MCP servers, and CLI worth setting up first —
is in [docs/platform-capabilities.md](docs/platform-capabilities.md).

## Status and compatibility

Stable, actively maintained. See [CHANGELOG.md](CHANGELOG.md).

| SDK version | Ruby | Rails |
|-------------|------|-------|
| 2.x         | 3.x, 4.x | 6.1 and later |
| 1.x         | 1.9.3 – 3.x (no longer maintained) | 5.x – 7.x |

CI covers Ruby 3.1, 3.2, 3.3, 3.4, and 4.0.

## Documentation

- [Bundled task docs](docs/README.md) — ship inside the gem, version-matched.
- [Ruby on Rails SDK guide](https://cloudinary.com/documentation/rails_integration) — the full documentation ([md](https://cloudinary.com/documentation/rails_integration.md)).

Documentation links in this README point at the browsable HTML page, with an `(md)`
companion link that returns the same page as raw Markdown. Inside `docs/` and `examples/`
the links are Markdown-only, since those files are written to be read by coding agents.
Either form works for any page: add `.md` for Markdown, drop it for HTML.

## For AI coding agents

- Contributing to this repo: read [AGENTS.md](AGENTS.md).
- Using the installed gem: the docs in the gem's `docs/` directory match your installed
  version and are the source of truth. Locate them with:

  ```bash
  ruby -e 'puts Gem::Specification.find_by_name("cloudinary").gem_dir + "/docs"'
  ```

  Start with [platform-capabilities](docs/platform-capabilities.md) before assuming a
  feature exists.

## Support

- SDK bugs and feature requests: [GitHub issues](https://github.com/cloudinary/cloudinary_gem/issues)
- Account and platform questions: [Cloudinary support](https://support.cloudinary.com)

## Security

See [SECURITY.md](SECURITY.md) for private vulnerability reporting. Keep your
`api_secret` in server-side code; for client uploads, use the server-signed pattern in
[Sign a browser upload](docs/sign-browser-upload.md).

## License

Released under the MIT license — see [LICENSE](LICENSE). Copyright (c) Cloudinary Ltd.
