# Moderate an upload

## When to use

Content uploaded by users must be reviewed before it is delivered. Moderation in
Cloudinary is stateful: an asset carries a moderation status, and your application is
responsible for delivering approved assets only.

**By default, `pending` does not block delivery.** A moderated asset is deliverable and
visible in the Media Library from the moment it is uploaded — the status is metadata you
gate on in your own code.

Blocking delivery of non-approved assets can be configured for your product environment.
It is not an upload parameter — contact Cloudinary support. Gate on the status in your
code regardless.

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

# 3. Record the verdict (or "rejected"); your code gates delivery on it.
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

**Nothing blocks delivery by default.** The delivery URL of a `pending` — or `rejected` —
asset works exactly like any other. Enforcement is your application's responsibility:
read the status and decide what to render.

Blocking non-approved assets can be configured for your product environment by Cloudinary
support. It is not an upload parameter, and you should still gate in your own code.

The statuses are `queued`, `pending`, `approved`, `rejected`, and `aborted`. None of them
block delivery by default.

## Automated moderation

Pass an add-on name instead of `"manual"` to get an automated verdict.

**Prerequisite — a human has to do this, not your code.** Every value below except
`manual` requires its add-on to be registered on the account first, from the
[Add-ons page](https://cloudinary.com/documentation/cloudinary_add_ons.md) in the console.
Some third-party add-ons also require reviewing and accepting the provider's terms of
service as part of registration. Neither step has an API; until both are done the add-on
value is rejected at upload. `manual` needs no add-on and no terms accepted, which is why
the flow above uses it.

| Value | Moderates | Add-on |
|---|---|---|
| `aws_rek` | images | Amazon Rekognition AI Moderation |
| `aws_rek_video` | video | Amazon Rekognition Video Moderation |
| `google_video_moderation` | video | Google AI Video Moderation |
| `webpurify` | images | WebPurify Image Moderation |
| `perception_point` | any asset | Perception Point Malware Detection |
| `duplicate:<threshold>` | images | Cloudinary Duplicate Image Detection |

```ruby
Cloudinary::Uploader.upload(source, moderation: "aws_rek")                              # images
Cloudinary::Uploader.upload(source, moderation: "google_video_moderation",
                                    resource_type: "video")                             # video
Cloudinary::Uploader.upload(source, moderation: "perception_point")                     # malware
```

Combine several with a pipe — the order is the order they run in, and `manual` must be
last (`"aws_rek|duplicate:0.9|manual"`). The first moderation starts as `pending` and the
rest as `queued`; if one rejects, the remaining become `aborted` and the asset's final
status is `rejected`. Always set a `notification_url` when requesting several.

Automated moderation is asynchronous: the upload returns `pending` and the verdict lands
seconds to minutes later. Do not block on it — set `notification_url` and react to the
webhook, or poll `Cloudinary::Api.resource(public_id)`. An asset may sit in `queued`
before the add-on reaches it. You can still override a machine decision with
`Cloudinary::Api.update` and `moderation_status` for human review.

Assert on shape, not on verdicts. Model output varies between runs and versions, so check
that a `moderation` entry exists with a known status value rather than expecting a
particular one.

## Design rules

- Model moderation as a state machine, not a boolean. Keep the pending state visible in
  your product (placeholder image, "under review" label) — and remember the URL works
  regardless, so the gate has to be in your code.
- Keep human override even with automated moderation — machine verdicts are drafts for
  anything with legal or brand consequences.
- Rejected assets stay in storage unless you delete them; decide your retention policy.

## Troubleshooting

- `result["moderation_status"]` is `nil` after upload — expected; the upload response does
  not carry that key. See [Result fields to keep](#result-fields-to-keep).
- `You don't have an active subscription for <add-on>`, raised as
  `Cloudinary::Api::RateLimited` — an unsubscribed or unentitled add-on surfaces as a
  **rate-limit** error rather than a permission error. Register the add-on on the Add-ons
  page in the console; some third-party add-ons also require accepting the provider's
  terms of service before they activate. `moderation: "manual"` needs no subscription and
  is the way to test the flow.
- Nothing returned from `resources_by_moderation` — the `kind` must match what you
  uploaded with (`"manual"` here), and the status must be one of `queued`, `pending`,
  `approved`, `rejected`, `aborted`.
- A pending asset delivers instead of 404ing — that is the default behavior, not a bug.
  Gate on the status in your own code, or contact support to have non-approved assets
  blocked for your product environment.
- Showing a rejected image — deliver `default_image` as a placeholder rather than relying
  on the URL failing, because it will not.
- `Moderation <value> moderation is not valid` — the moderation value is misspelled; use
  one of the values in the table above.
- Asset still not visible after approving — CDN caches the earlier response; deliver with
  the asset `version` or invalidate. See
  [Transform and deliver an image](transform-and-deliver-image.md#cache-behavior).

## Related

- Runnable example: `examples/moderate-upload.rb`
- [Search and manage assets](search-and-manage-assets.md)
- [Moderation guide](https://cloudinary.com/documentation/moderate_assets.md)
