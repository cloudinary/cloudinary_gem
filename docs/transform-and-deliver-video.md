# Transform and deliver a video

## When to use

Generate delivery URLs and player markup for video: transcoded derived assets, poster
frames, and adaptive streaming manifests. URL generation is local — no network call, no
secret required.

Video URLs need `resource_type: "video"`. Without it you get an image URL that will 404.

## Transcoded derived asset

```ruby
require "cloudinary" # only cloud_name is needed for URL generation

video_url = Cloudinary::Utils.cloudinary_url(
  "dog",
  resource_type: "video",
  width: 640,
  height: 360,
  crop: "fill",
  quality: "auto",
  format: "mp4"
)
puts video_url
# https://res.cloudinary.com/<cloud>/video/upload/c_fill,h_360,q_auto,w_640/dog.mp4
```

## Poster frame

A still from the video is just the same asset delivered as an image format.
`start_offset` picks the timestamp in seconds:

```ruby
poster_url = Cloudinary::Utils.cloudinary_url(
  "dog",
  resource_type: "video",
  format: "jpg",
  start_offset: "2"
)
puts poster_url
# https://res.cloudinary.com/<cloud>/video/upload/so_2/dog.jpg
```

## Adaptive streaming (HLS / DASH)

Deliver a manifest instead of a single file, using a
[streaming profile](https://cloudinary.com/documentation/adaptive_bitrate_streaming.md):

```ruby
hls_url = Cloudinary::Utils.cloudinary_url(
  "dog",
  resource_type: "video",
  format: "m3u8",           # "mpd" for DASH
  streaming_profile: "full_hd"
)
puts hls_url
# https://res.cloudinary.com/<cloud>/video/upload/sp_full_hd/dog.m3u8
```

A streaming profile produces a ladder of derived assets at different resolutions and
bitrates (the industry term for these is *renditions*) and the manifest lets the player
switch between them as bandwidth changes.

For best results, generate those derived assets eagerly at upload time
(`eager: [{ streaming_profile: "full_hd", format: "m3u8" }], eager_async: true`) so the
first viewer does not wait for transcoding.

## Rails: the video tag

`cl_video_tag` renders a `<video>` element with a poster and multiple `<source>` formats
(webm, mp4, ogv) already filled in:

```erb
<%= cl_video_tag("dog", width: 640, crop: "scale") %>
```

```html
<video width="640" poster="https://res.cloudinary.com/<cloud>/video/upload/c_scale,w_640/dog.jpg">
  <source src="https://res.cloudinary.com/<cloud>/video/upload/c_scale,w_640/dog.webm" type="video/webm" />
  <source src="https://res.cloudinary.com/<cloud>/video/upload/c_scale,w_640/dog.mp4" type="video/mp4" />
  <source src="https://res.cloudinary.com/<cloud>/video/upload/c_scale,w_640/dog.ogv" type="video/ogg" />
</video>
```

Related helpers: `cl_video_path`, `cl_video_thumbnail_tag`, `cl_video_thumbnail_path`.
See [Use with Rails](use-with-rails.md).

## Troubleshooting

- 404 on a video URL — `resource_type: "video"` is missing, so an `/image/upload/` URL
  was generated. This is the most common video URL mistake.
- 404 on a video you just uploaded with `upload_large` — it may have landed as `raw`
  because `resource_type` was omitted at upload time. See
  [Upload a large video](upload-large-video.md#resource_type-is-not-optional).
- The manifest loads but playback stalls — the derived assets are still transcoding.
  Generate them eagerly, or wait for the `notification_url` webhook.
- 401 on a delivery URL from a freshly provisioned cloud — delivery is IP-locked until
  the cloud is claimed. See [Get Cloudinary credentials](get-credentials.md).

## Related

- Runnable example: `examples/transform-and-deliver-video.rb`
- [Upload a large video](upload-large-video.md)
- [Transform and deliver an image](transform-and-deliver-image.md)
- [Video manipulation guide](https://cloudinary.com/documentation/rails_video_manipulation.md)
