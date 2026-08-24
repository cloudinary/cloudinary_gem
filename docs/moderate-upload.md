# Moderate an upload

## When to use

User-generated content should be reviewed before it is shown publicly. Flagging an asset
for moderation at upload time keeps it out of normal delivery listings until it is
approved or rejected.

This is the per-asset moderation flag this SDK sets. Rule-based review across a whole
product environment is [Cloudinary Moderation](https://cloudinary.com/documentation/cloudinary_moderation.md),
a separate platform product.

## Complete flow

```ruby
require "cloudinary" # reads CLOUDINARY_URL

# 1. Upload flagged for manual review
result = Cloudinary::Uploader.upload(
  "https://res.cloudinary.com/demo/image/upload/sample.jpg",
  public_id: "examples/moderated-sample",
  moderation: "manual" # or an add-on: "aws_rek", "google_video_moderation", ...
)

puts result["moderation"].inspect
# [{"kind" => "manual", "status" => "pending"}]

# 2. List everything awaiting review
pending = Cloudinary::Api.resources_by_moderation("manual", "pending", max_results: 100)
pending["resources"].each { |asset| puts asset["public_id"] }

# 3. Approve (or "rejected")
updated = Cloudinary::Api.update("examples/moderated-sample", moderation_status: "approved")
puts updated["moderation"].inspect
# [{"kind" => "manual", "status" => "approved", "updated_at" => "..."}]
```

## Result fields to keep

The moderation state is reported in **two different shapes**, and the difference bites:

- The **upload result** has a `moderation` array and **no `moderation_status` key at all**.
  Reading `result["moderation_status"]` gives `nil`, not the status.
- `Cloudinary::Api.resource` and `Cloudinary::Api.update` return both a `moderation`
  array and a `moderation_status` string.

Read the status from the array to work with every response shape:

```ruby
status = result["moderation"]&.first&.fetch("status", nil)
```

Store `asset_id` alongside your own record of the review; `public_id` can change if the
asset is renamed or moved.

## Delivery while pending

A pending asset is not publicly delivered — treat "pending" as "do not display yet" and
show it only in your review UI. Approving makes it deliver normally; rejecting keeps it
blocked.

## Troubleshooting

- `result["moderation_status"]` is `nil` after upload — expected; the upload response does
  not carry that key. See [Result fields to keep](#result-fields-to-keep).
- `Rate limit exceeded` (`Cloudinary::Api::RateLimited`) when enabling an add-on
  moderation kind — an unsubscribed or unentitled add-on surfaces as a **rate-limit**
  error rather than a permission error. Check the add-on is enabled for the account
  before assuming you are calling it wrong.
- Nothing returned from `resources_by_moderation` — the `kind` must match what you
  uploaded with (`"manual"` here), and the status must be one of `pending`, `approved`,
  `rejected`.
- Asset still not visible after approving — CDN caches the earlier response; deliver with
  the asset `version` or invalidate. See
  [Transform and deliver an image](transform-and-deliver-image.md#cache-behavior).

## Related

- Runnable example: `examples/moderate-upload.rb`
- [Search and manage assets](search-and-manage-assets.md)
- [Moderation guide](https://cloudinary.com/documentation/moderate_assets.md)
