# Search and manage assets

## When to use

Find assets by indexed fields, read or update asset attributes, and administer your media
library from the server. These use the Admin and Search APIs, which are **rate-limited** —
treat them as management operations, not a per-request database.

## Search with the query builder

Expressions use Cloudinary's search syntax — fields, operators, ranges, and boolean
combinations are listed in the
[search expression reference](https://cloudinary.com/documentation/search_expressions.md).
The builder is chainable and `execute` performs the call:

```ruby
require "cloudinary" # reads CLOUDINARY_URL

result = Cloudinary::Search
  .expression("resource_type:image AND public_id:examples/*")
  .sort_by("created_at", "desc")
  .max_results(30)
  .execute

result["resources"].each do |asset|
  puts [asset["asset_id"], asset["public_id"], asset["bytes"], asset["created_at"]].join(" ")
end

puts result["total_count"]

# Pagination: pass the cursor back until it is absent
if result["next_cursor"]
  page2 = Cloudinary::Search
    .expression("resource_type:image AND public_id:examples/*")
    .next_cursor(result["next_cursor"])
    .execute
  puts "Second page: #{page2["resources"].size} asset(s)"
end
```

Other builder methods: `with_field` (request `tags`, `context`, ...), `fields` (limit the
returned attributes), `aggregate`, `ttl`, and `to_url` for a signed client-side search URL.

### Matching a folder

`folder:` only matches when the product environment uses fixed folders. In a
**dynamic-folder** environment — the default for new clouds — a `public_id` of
`examples/uploaded-sample` is *not* in a folder named `examples`, and
`folder:examples` returns **zero results with no error**:

```ruby
Cloudinary::Search.expression("folder:examples").execute["total_count"]                # => 0
Cloudinary::Search.expression("public_id:examples/*").execute["total_count"]           # => 1
```

Match on the `public_id` prefix, or query `asset_folder:` if you deliberately set one at
upload time. An expression naming a field that does not apply is not an error — it simply
matches nothing.

## Read and update a single asset

```ruby
details = Cloudinary::Api.resource_by_asset_id(stored_asset_id)

Cloudinary::Api.update(
  details["public_id"],
  tags: "featured",
  context: "alt=Sample image from the bundled upload example"
)
```

`update` has no asset-id variant — look the asset up first and use its `public_id`.

Bulk reads and lifecycle: `Cloudinary::Api.resources_by_asset_ids`,
`restore_by_asset_ids`, `delete_resources_by_asset_ids`.

## Deletion — destructive, no undo without backups

```ruby
Cloudinary::Uploader.destroy("examples/uploaded-sample")        # one asset
# Cloudinary::Api.delete_resources([...ids])                    # bulk — double-check inputs
# Cloudinary::Api.delete_resources_by_prefix("examples/")       # by prefix — extremely destructive
```

Prefer explicit ID lists over prefix deletion. Enable backups on the product environment
if you need restore (`Cloudinary::Api.restore`).

## Handling errors

Admin and Search calls raise typed exceptions, so you can rescue by class:

```ruby
begin
  Cloudinary::Api.resource("examples/does-not-exist")
rescue Cloudinary::Api::NotFound => e
  warn e.message # "Resource not found - examples/does-not-exist"
rescue Cloudinary::Api::RateLimited => e
  warn "Slow down: #{e.message}"
end
```

Available classes: `NotFound`, `NotAllowed`, `AlreadyExists`, `RateLimited`,
`BadRequest`, `AuthorizationRequired`, `GeneralError` — all under
`Cloudinary::Api::Error`. **`Cloudinary::Uploader` does not use them**; see
[Troubleshoot errors](troubleshoot-errors.md).

Admin responses expose rate-limit headers directly:

```ruby
response = Cloudinary::Api.resources(max_results: 1)
puts response.rate_limit_remaining # e.g. 498
puts response.rate_limit_allowed
puts response.rate_limit_reset_at
```

## Troubleshooting

- `Rate limit exceeded` (`Cloudinary::Api::RateLimited`) — too many Admin API calls. Batch
  your work and retry later; read `rate_limit_remaining` to slow down before being cut off.
- Stale or empty search results right after an upload — the search index lags writes by a
  short interval. For read-after-write flows use `Cloudinary::Api.resource_by_asset_id`
  instead of searching.
- Zero results from an expression you expected to match — check the field applies to your
  folder mode; see [Matching a folder](#matching-a-folder).
- `Query Error (at position N)` (`Cloudinary::Api::BadRequest`) — invalid syntax. Search
  rejects **leading** wildcards: `public_id:*ample*` fails, `public_id:examples/*` works.

## Related

- Runnable example: `examples/search-and-manage-assets.rb`
- [Use structured metadata](use-structured-metadata.md)
- [Asset administration guide](https://cloudinary.com/documentation/rails_asset_administration.md)
