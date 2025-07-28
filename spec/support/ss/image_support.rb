def extract_image_info(filepath)
  image = MiniMagick::Image.open(filepath)

  {
    filename: ::File.basename(filepath),
    format: image.type,
    width: image.width,
    height: image.height,
    colorspace: image.colorspace,
    size: image.size,
    resolution: { x: image.resolution[0], y: image.resolution[1] }
  }
ensure
  image.destroy! if image
end

def extract_image_info_from_data_url(data_url)
  expect(data_url).to start_with("data:image/png;base64,")
  png_data = data_url[22, data_url.length].then do |base64|
    Base64.urlsafe_decode64(base64)
  end

  image = MiniMagick::Image.read(png_data)

  {
    format: image.type,
    width: image.width,
    height: image.height,
    colorspace: image.colorspace,
    size: image.size,
    resolution: { x: image.resolution[0], y: image.resolution[1] }
  }
ensure
  image.destroy! if image
end
