# Use structured metadata

## When to use

Structured metadata gives assets **typed, validated fields** defined once for the product
environment — alt text, a photographer name, a category from a fixed list. Use it when
values must be validated, queried, or shared across a team.

For free-form key/value pairs with no schema, use `context:` instead. For labels with no
value, use `tags:`.

## Define a field once

Fields are environment-level configuration. Create them once (or in the Console), not per
upload:

```ruby
require "cloudinary" # reads CLOUDINARY_URL

field = Cloudinary::Api.add_metadata_field(
  external_id: "alt_text",
  label: "Alt text",
  type: "string" # also: integer, date, enum, set
)
puts field["external_id"] # "alt_text"
```

Manage them with `Cloudinary::Api.list_metadata_fields`,
`metadata_field_by_field_id`, `update_metadata_field`, `delete_metadata_field`.

`add_metadata_field` raises `Cloudinary::Api::BadRequest` if the `external_id` already
exists, so creating fields at boot needs a rescue or a prior existence check.

## Set values at upload time

```ruby
result = Cloudinary::Uploader.upload(
  "https://res.cloudinary.com/demo/image/upload/sample.jpg",
  public_id: "examples/metadata-sample",
  metadata: { alt_text: "A close-up of a coastline" }
)
puts result["metadata"].inspect
# {"alt_text" => "A close-up of a coastline"}
```

## Update values on existing assets

```ruby
updated = Cloudinary::Uploader.update_metadata(
  { alt_text: "Updated caption" },
  ["examples/metadata-sample"] # accepts a list of public_ids
)
puts updated["public_ids"].inspect
# ["examples/metadata-sample"]
```

`Cloudinary::Api.update(public_id, metadata: {...})` sets the same values for a single
asset.

## Undefined keys are rejected, not ignored

A key with no matching field definition **fails the whole call**:

```ruby
Cloudinary::Uploader.upload(source, metadata: { not_a_real_field: "x" })
# CloudinaryException: Metadata External IDs do not exist: ["not_a_real_field"]
```

Nothing is silently dropped and no partial write happens — the upload does not occur at
all. Define the field first, and treat a typo in an `external_id` as a hard failure.

## Query by metadata

Metadata fields are searchable once populated:

```ruby
result = Cloudinary::Search
  .expression('metadata.alt_text:"Updated caption"') # or a trailing wildcard: Updated*
  .with_field("metadata")                            # required: omitted from results by default
  .execute
puts result["total_count"]
```

Two syntax rules that both surface as `Cloudinary::Api::BadRequest`:

- **Leading wildcards are rejected.** `metadata.alt_text:*aption*` is a syntax error;
  `Updated*` works.
- **A bare `*` is rejected.** `metadata.alt_text:*` does not mean "has any value" — to
  find assets where a field is populated, query a value or a prefix.

Newly written values take a short interval to become searchable; a search immediately
after an upload can return zero.

## Troubleshooting

- `Metadata External IDs do not exist: [...]` — the field is not defined in this product
  environment, or the `external_id` is misspelled. Create it first.
- `Cloudinary::Api::BadRequest` from `add_metadata_field` — the `external_id` already
  exists, or the `type` is not one of the supported types.
- A value you set does not come back from search — request it explicitly with
  `.with_field("metadata")`; search omits it by default.
- Validation errors on `enum` / `set` fields — the value must be one of the datasource
  entries. Manage those with `update_metadata_field_datasource`.

## Related

- Runnable example: `examples/use-structured-metadata.rb`
- [Search and manage assets](search-and-manage-assets.md)
- [Structured metadata guide](https://cloudinary.com/documentation/structured_metadata.md)
