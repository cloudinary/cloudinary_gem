# Troubleshoot errors

## When to use

An SDK call raised, a delivery URL returned the wrong thing, or configuration is not
being picked up.

## Exception classes are not consistent across entry points

This is the single most important thing to know when writing `rescue` clauses. The same
condition raises **different classes** depending on which class you called:

| Entry point | Missing configuration | API error response |
|---|---|---|
| `Cloudinary::Uploader` | `CloudinaryException` — `"Must supply api_key"` | `CloudinaryException` |
| `Cloudinary::Api` | **`RuntimeError`** — `"Must supply cloud_name"` | `Cloudinary::Api::NotFound`, `RateLimited`, `BadRequest`, ... |
| `Cloudinary::Search` | **`RuntimeError`** — `"Must supply cloud_name"` | same typed classes as `Cloudinary::Api` |
| `Cloudinary::Utils.cloudinary_url` | `CloudinaryException` — `"Must supply cloud_name in tag or in configuration"` | n/a (local) |

The API-error classes are fine under a single rescue: `Cloudinary::Api::Error` descends
from `CloudinaryException`, so `rescue CloudinaryException` catches `NotFound`,
`RateLimited`, and the rest.

The gap is **configuration** errors. `Cloudinary::Api` and `Cloudinary::Search` raise a
bare `RuntimeError` for missing config, and `RuntimeError` is not a `CloudinaryException`:

```ruby
# INCOMPLETE — catches API errors, but a missing cloud_name escapes as RuntimeError
begin
  Cloudinary::Api.resource("x")
rescue CloudinaryException => e
  warn e.message
end
```

Rescue `StandardError` when you need one handler to cover configuration problems across
entry points, and rescue the typed classes for API responses:

```ruby
begin
  Cloudinary::Api.resource("examples/uploaded-sample")
rescue Cloudinary::Api::NotFound
  warn "No such asset"
rescue StandardError => e            # catches RuntimeError and CloudinaryException
  warn "Cloudinary call failed: #{e.message}"
  exit 1
end
```

Admin API classes all descend from `Cloudinary::Api::Error`, so
`rescue Cloudinary::Api::Error` covers every HTTP error from `Api` and `Search` while
still letting configuration errors through.

## Configuration errors

| Message | Cause |
|---|---|
| `Must supply cloud_name` | No configuration found — `CLOUDINARY_URL` unset or malformed. It must start with `cloudinary://`. |
| `Must supply api_key` / `Must supply api_secret` | Partial configuration; URL building works but authenticated calls do not. |
| `Invalid Signature` | Wrong `api_secret` for this cloud. Uploads report a bad secret this way instead of naming it. |
| Config is empty in Rails | The `config/cloudinary.yml` section must match `Rails.env`. |
| `cloud_name` right but `api_key` stale | `CLOUDINARY_CLOUD_NAME` is set, which makes the SDK **ignore `CLOUDINARY_URL` entirely**. See [Configure Cloudinary](configure-cloudinary.md#precedence). |

Check what the SDK actually resolved:

```ruby
require "cloudinary"
puts Cloudinary.config.cloud_name.inspect
puts Cloudinary.config.api_key.inspect
puts Cloudinary.config.api_secret.nil? ? "secret: MISSING" : "secret: present"
```

Never print the secret itself.

## Upload errors

| Message | Cause |
|---|---|
| `File size too large` | Either the 100 MB per-request ceiling, or your environment's asset maximum. See [Upload an image](upload-image.md#size-limits). |
| `Resource not found - <url>` | A remote source URL is not publicly reachable from Cloudinary. |
| `All parts except EOF-chunk must be larger than 5mb` | `chunk_size` below the 5 MB minimum in `upload_large`. |
| `Metadata External IDs do not exist` | Undefined structured-metadata key; the whole upload is rejected. See [Use structured metadata](use-structured-metadata.md). |
| Upload replaced an asset unexpectedly | `overwrite` defaults to true. See [Upload an image](upload-image.md#re-uploading-the-same-public_id). |

## Admin and Search errors

| Class | Meaning |
|---|---|
| `Cloudinary::Api::NotFound` | The `public_id` or `asset_id` does not exist (or is a different `resource_type`). |
| `Cloudinary::Api::RateLimited` | Too many Admin calls — **also** how an unsubscribed add-on surfaces. |
| `Cloudinary::Api::BadRequest` | Invalid parameters or search syntax, e.g. a leading wildcard (`*abc*`). |
| `Cloudinary::Api::AuthorizationRequired` | Bad or missing credentials. |
| `Cloudinary::Api::NotAllowed` | Authenticated but not permitted — plan or entitlement. |

Search returning zero with no error usually means the expression is valid but matches
nothing — commonly `folder:` in a dynamic-folder environment. See
[Search and manage assets](search-and-manage-assets.md#matching-a-folder).

### `423` while an asset is still processing

The asset is not yet available for the operation you requested — common right after
uploading a large video, or while an eager or add-on-driven transformation is still
running. This is transient: retry with backoff rather than treating it as a failure. For
long jobs, prefer `eager_async: true` with a `notification_url` over polling.

423 is **not** in this SDK's status-to-exception map (`lib/cloudinary/base_api.rb`), so it
falls through to the unmapped-status branch and raises
`Cloudinary::Api::GeneralError` — with the raw response body in the message, not the
parsed `error.message` you get from mapped statuses:

```
Server returned unexpected status code - 423 - {"error":{"message":"..."}}
```

`rescue Cloudinary::Api::Error` still catches it, since `GeneralError` descends from
`Error`. But do not match on the message text, and do not treat `GeneralError` as
necessarily fatal — a 423 is worth a retry where a 500 usually is not.

## Delivery URL problems

| Symptom | Cause |
|---|---|
| 401 on every delivery URL | A freshly provisioned cloud is IP-locked until claimed. See [Get Cloudinary credentials](get-credentials.md). |
| 404 on a video URL | `resource_type: "video"` omitted, so an `/image/upload/` URL was built. |
| 404 on an asset you just uploaded with `upload_large` | It landed as `raw` because `resource_type` was omitted. See [Upload a large video](upload-large-video.md#resource_type-is-not-optional). |
| Stale image after re-upload | CDN cache; deliver with the asset `version`. |
| Unexpected `?_a=` on URLs | SDK analytics; harmless. Pass `analytics: false` to omit. |
| An unexpected `/v1/` path segment | Placeholder inserted when the `public_id` contains a slash and no version is known. It delivers correctly. |

## Do not log the whole error or response

Admin and upload payloads can include your `api_key`, and config objects hold the
`api_secret`. Log `e.message`, not the object or the request parameters.

## Getting help

Include the `public_id`, the `cloud_name`, the exception class and message, and the SDK
version (`Cloudinary::VERSION`) when opening an issue or support ticket.

## Related

- [Configure Cloudinary](configure-cloudinary.md)
- [Troubleshooting index](https://cloudinary.com/documentation/llms-troubleshooting.txt)
