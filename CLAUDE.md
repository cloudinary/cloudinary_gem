@AGENTS.md

# CLAUDE.md — cloudinary_gem

## What this repo is

The official Cloudinary Ruby/Rails server SDK (`cloudinary` gem): signed uploads, Admin/Search API, transformation URL generation, Rails view helpers (`cl_image_tag`, `cl_video_tag`), and Active Storage / CarrierWave integration — all on the server where the `api_secret` stays private.

## Key constraints and gotchas

- **Test suite hits the live API.** Specs require a real `CLOUDINARY_URL` and network access — not hermetic. Use a throwaway cloud; some specs create and delete real assets. `rspec-retry` is enabled for flaky network specs.
- **`CLOUDINARY_URL` vs discrete vars conflict.** If `CLOUDINARY_CLOUD_NAME` is present in the environment, the gem ignores `CLOUDINARY_URL` and reads the discrete `CLOUDINARY_*` vars instead. Pick one style — don't mix them.
- **Rails-only helpers.** `cl_image_tag` / `cl_video_tag` load via Railtie and are only available where Action View helpers are (controllers, views, helpers). In a plain Ruby script or background job, use `Cloudinary::Utils.cloudinary_url(…)` instead.
- **No linter configured.** No `.rubocop.yml`, no rubocop in the gemspec. Don't invent a `lint` task.
- **Default branch is `master`.** Branch from it; CI ("Ruby Test 💎") runs on pushes/PRs to `master` across the Ruby matrix (3.1, 3.2, 3.3, 3.4, 4.0).
- **HTTP stack is Faraday.** Keep new request code on `faraday` / `faraday-multipart` / `faraday-follow_redirects` — don't add a second HTTP client.
- **Version bump:** edit `lib/cloudinary/version.rb` — not the gemspec.
- **Supported versions (2.x):** Ruby `>= 3, < 5`; Rails 6/7/8. For Ruby 1.9.3/2.x, stay on the 1.x line.

## Verified build and test commands

```bash
bundle install                                       # install gem + dev dependencies
export CLOUDINARY_URL=cloudinary://<key>:<secret>@<cloud>
bundle exec rspec --format documentation --color    # full suite (what CI runs)
bundle exec rspec -f d                              # shorthand the project uses
bundle exec rspec spec/uploader_spec.rb             # single spec file
rake spec                                           # equivalent via Rake
```
