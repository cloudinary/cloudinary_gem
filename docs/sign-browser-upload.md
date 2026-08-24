# Sign a browser upload

## When to use

A browser or mobile app uploads directly to Cloudinary, but you want the operation
authorized by your server. The `api_secret` stays on the server; the client receives a
signature that is valid for **1 hour** from the `timestamp` it was signed with.

For uploads without a server round-trip, use an
[unsigned upload preset](https://cloudinary.com/documentation/upload_presets.md) instead —
deliberately restricted, because anyone can use it.

## Server: signing endpoint

```ruby
require "cloudinary" # reads CLOUDINARY_URL

# Example Rails controller action
class SignaturesController < ApplicationController
  def create
    timestamp = Time.now.to_i
    params_to_sign = { timestamp: timestamp, folder: "user-uploads" } # sign ONLY what the client may use

    signature = Cloudinary::Utils.api_sign_request(params_to_sign, Cloudinary.config.api_secret)

    render json: {
      signature:  signature,
      timestamp:  timestamp,
      folder:     params_to_sign[:folder],
      api_key:    Cloudinary.config.api_key,
      cloud_name: Cloudinary.config.cloud_name
    }
  end
end
```

`Cloudinary::Utils.api_sign_request` is local — it performs no network call and returns a
hex SHA-1 digest string.

## Browser: use the signature

```js
const { signature, timestamp, folder, api_key, cloud_name } =
  await (await fetch('/signatures', { method: 'POST' })).json();

const form = new FormData();
form.append('file', fileInput.files[0]);
form.append('api_key', api_key);
form.append('timestamp', timestamp);
form.append('signature', signature);
form.append('folder', folder); // send back exactly what the server signed

// 'auto' detects image / video / raw from the file itself
const response = await fetch(`https://api.cloudinary.com/v1_1/${cloud_name}/auto/upload`, {
  method: 'POST',
  body: form
});
const asset = await response.json(); // contains public_id, secure_url, ...
```

## Rules

- Every parameter the browser sends (except `file`, `api_key`, `signature`, and
  `resource_type`) must be included in the signed parameter set, or Cloudinary rejects
  the request with `Invalid Signature`. To let the client set a tag, `public_id`, or
  transformation, add it to the signed params on the server first.
- Signatures embed the timestamp and are accepted for 1 hour after it. Generate one per
  upload rather than caching and reusing them.
- Keep the `api_secret` in server code only; the client receives just the signature,
  timestamp, `api_key`, and `cloud_name`.

## Rails alternative: the bundled form helpers

This gem ships `cl_upload_tag` / `cl_form_tag` view helpers that render a signed upload
field for you. They are convenient for classic server-rendered forms; for a JavaScript
front end, prefer the explicit endpoint above so the client controls the request. See
[Use with Rails](use-with-rails.md).

## Troubleshooting

- `Invalid Signature` — the client sent a parameter that was not signed, or sent values
  differing from the signed ones.
- `Stale request` — the signature is more than 1 hour old. Fetch a fresh one at upload
  time instead of signing on page load; also check that your server clock is accurate,
  since a skewed clock produces timestamps that are stale on arrival.

## Related

- Runnable example: `examples/sign-browser-upload.rb`
- [Generating authentication signatures](https://cloudinary.com/documentation/upload_images.md#generating_authentication_signatures)
