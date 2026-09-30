# Contributor guide for coding agents

This file is for agents contributing to this repository. If you are *using* the installed
`cloudinary` gem in another project, read the bundled docs instead — find them with
`ruby -e 'puts Gem::Specification.find_by_name("cloudinary").gem_dir + "/docs"'`.

## Commands

```bash
bundle install                        # install dependencies
bundle exec rspec                     # full suite — HITS A LIVE CLOUD, see Testing
bundle exec rspec spec/utils_spec.rb  # a single file
bundle exec rspec spec/active_storage spec/carriewave_spec.rb  # integration adapters
gem build cloudinary.gemspec          # build the gem; inspect what ships
```

`CLOUDINARY_URL` must be set for most of the suite. `tools/get_test_cloud.sh` allocates a
throwaway cloud (this is what CI uses); `npx @cloudinary/cloud` also works.

There is **no linter configured** in this repo — no RuboCop config exists. Do not add one
as part of an unrelated change.

## Testing

- **The suite is not mocked.** Unlike the other Cloudinary SDKs, `spec/` has no
  unit/integration split: most files perform real uploads and Admin API calls against the
  `CLOUDINARY_URL` cloud. Never point it at a production environment.
- Specs tag their fixtures (`TEST_TAG`, `TIMESTAMP_TAG` in `spec/spec_helper.rb`) and
  clean up by tag. Preserve that pattern so runs do not leak assets.
- `spec/active_storage/dummy/` is a real dummy Rails app with a database; those specs boot
  Rails. `spec/carriewave_spec.rb` stubs CarrierWave — it is **not** a dependency of this
  gem.
- Nondeterministic AI output (captions, tags, moderation verdicts) must be asserted by
  request shape, state transition, and response schema — never by exact output values.
- `rspec-retry` is enabled; a flaky live call may retry rather than fail outright.

## Project structure

- `lib/cloudinary.rb` — entry point, config loading, Rails hook-in.
- `lib/cloudinary/uploader.rb` — Upload API. Raises `CloudinaryException` for everything.
- `lib/cloudinary/api.rb` — Admin API. Raises typed subclasses of
  `Cloudinary::Api::Error` (`NotFound`, `RateLimited`, ...) defined in `base_api.rb`.
- `lib/cloudinary/utils.rb` — URL generation and signing; the largest and most
  transformation-logic-dense file.
- `lib/cloudinary/search.rb` — chainable Search API builder.
- `lib/cloudinary/helper.rb`, `video_helper.rb` — Rails view helpers (`cl_image_tag` etc.).
- `lib/active_storage/service/cloudinary_service.rb` — Active Storage service; patches
  `ActiveStorage::Blob`, so load order matters (see docs/upload-with-activestorage.md).
- `lib/cloudinary/carrier_wave*` — CarrierWave storage adapter, loaded only when
  `CarrierWave` is defined.
- `docs/` — version-matched Markdown docs shipped in the gem.
- `examples/` — runnable task examples shipped in the gem; one per `docs/` task page.
- `samples/` — **legacy** sample applications, not part of the tested example set and not
  shipped in the gem. Do not treat them as current guidance.
- `spec/` — the test suite; `tools/` — cloud allocation and release shell scripts.

## Code style

- Two-space indent, `snake_case`, module functions via `def self.method`.
- Public API methods take positional arguments then a trailing options hash, and pass
  unrecognized options through to the API rather than validating them:

```ruby
def self.example_method(public_id, options = {})
  call_api("example", options) do
    { :timestamp => Time.now.to_i, :public_id => public_id }
  end
end
```

- Results are `Hash` objects with **string** keys. Do not convert to symbols.
- The version lives in exactly one place, `lib/cloudinary/version.rb`, and
  `tools/get_test_cloud.sh` greps it — do not reformat that line.

## Git workflow

- Branch from `master`; keep changes focused; one topic per pull request.
- Run the suite against a throwaway cloud before opening a PR.
- Do not rewrite published `CHANGELOG.md` entries; add new entries at the top. Docs-only
  changes get no changelog entry.
- Never commit credentials. `config/cloudinary.yml` is gitignored for this reason — it is
  a local dev file and must not be added.

## Boundaries

**Always**
- Keep `docs/` and `examples/` consistent with the code they document, 1:1 per task.
- Verify a documented behavior by running it against a real cloud before writing it down.
- Keep API secrets out of examples, docs, specs, and fixtures.

**Ask first**
- Changing supported Ruby or Rails versions, dependencies, or the gemspec `files` list.
- Renaming or removing any public method, or changing an exception class raised.
- Changing release, CI, or publishing configuration.

**Never**
- Commit credentials or real account identifiers.
- Point the test suite at a production Cloudinary environment.
- Add a linter, reformat unrelated files, or modify `samples/` as part of another change.
- Document a Cloudinary platform capability as an SDK method unless this gem implements
  it (see docs/platform-capabilities.md).
