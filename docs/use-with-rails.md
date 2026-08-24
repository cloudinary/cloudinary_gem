# Use with Rails

## When to use

You are in a Rails application and want delivery URLs, image and video tags, or upload
forms in views. This gem integrates with Rails directly — no companion package.

For attaching uploads to models, see [Active Storage](upload-with-activestorage.md) or
[CarrierWave](upload-with-carrierwave.md).

## Setup

Add the gem and set credentials. No initializer or `require` is needed — a railtie wires
the view helpers in automatically:

```ruby
# Gemfile
gem "cloudinary"
```

```bash
export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
```

In production, put the same value in Rails encrypted credentials or your platform's
environment settings.

### Credentials: do not commit cloudinary.yml

The gem also reads `config/cloudinary.yml`, keyed by `Rails.env`:

```yaml
development:
  cloud_name: my-cloud
  enhance_image_tag: true
  static_file_support: false
```

That file is a convenient place for **non-secret** settings, but `api_key` and
`api_secret` in a checked-in YAML file is a credential leak. Keep secrets in
`CLOUDINARY_URL` or encrypted credentials, and add `config/cloudinary.yml` to
`.gitignore` if it holds any.

`CLOUDINARY_URL` overrides `cloudinary.yml`; see
[precedence](configure-cloudinary.md#precedence) — including the
`CLOUDINARY_CLOUD_NAME` trap.

## Image tags

`cl_image_tag` takes a `public_id` plus any transformation options and renders an `<img>`:

```erb
<%= cl_image_tag("sample", width: 200, height: 200, crop: "fill",
                 gravity: "auto", fetch_format: "auto", quality: "auto") %>
```

```html
<img width="200" height="200"
     src="https://res.cloudinary.com/<cloud>/image/upload/c_fill,f_auto,g_auto,h_200,q_auto,w_200/sample" />
```

URLs are HTTPS by default. `width` and `height` are also emitted as HTML attributes;
pass `html_width` / `html_height` to control the attributes independently of the
transformation.

Companion helpers:

- `cl_image_path(public_id, options)` — the URL only.
- `cl_picture_tag(public_id, options, sources)` — a `<picture>` with `<source>` entries.
- `cloudinary_url(public_id, options)` — same as `Cloudinary::Utils.cloudinary_url`.

For `cl_picture_tag`, each entry in `sources` needs its own transformation options plus
the media condition you want; verify the rendered markup, since an entry without
transformation options produces a `<source>` identical to the fallback.

## Video tags

```erb
<%= cl_video_tag("dog", width: 640, crop: "scale") %>
```

Renders a `<video>` with a poster frame and webm/mp4/ogv `<source>` elements. See
[Transform and deliver a video](transform-and-deliver-video.md). Also available:
`cl_video_path`, `cl_video_thumbnail_tag`, `cl_video_thumbnail_path`.

## Upload forms

For a server-rendered form that uploads straight to Cloudinary, `cl_upload_tag` renders a
signed file field:

```erb
<%= form_tag("/photos") do %>
  <%= cl_upload_tag(:photo, tags: "user-upload") %>
  <%= submit_tag "Upload" %>
<% end %>
```

The signature is generated server-side at render time, so the `api_secret` never reaches
the browser. For a JavaScript front end, prefer an explicit signing endpoint —
[Sign a browser upload](sign-browser-upload.md).

## enhance_image_tag

With `enhance_image_tag: true` in configuration, the gem also patches Rails' built-in
`image_tag` so existing calls route through Cloudinary. It is off by default and changes
the behaviour of a core Rails helper — prefer calling `cl_image_tag` explicitly in new
code.

## Troubleshooting

- `undefined method 'cl_image_tag'` — the railtie did not load. It requires
  `ActionView::Base` to be defined; in a plain Ruby script use
  `Cloudinary::Utils.cloudinary_url` instead.
- Helpers work in development but not test — `config/cloudinary.yml` has no section
  matching `Rails.env`.
- `Must supply cloud_name in tag or in configuration` — credentials are not reaching the
  app; check `Cloudinary.config.cloud_name` in `rails console`.
- Tag renders but media 404s — the `public_id` does not exist in this cloud, or it needs
  `resource_type: "video"`.

## Related

- Runnable example: `examples/use-with-rails.rb` — renders the helper output without a
  full Rails app.
- [Upload with Active Storage](upload-with-activestorage.md)
- [Upload with CarrierWave](upload-with-carrierwave.md)
- [Rails SDK guide](https://cloudinary.com/documentation/rails_integration.md)
