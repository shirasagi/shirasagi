module GravatarHelper
  def gravatar_image_url(email, size = 150)
    "https://gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}?s=#{size}"
  end

  def gravatar_image_tag(email, size = 150, options = {})
    tag(:img, options.merge({ src: gravatar_image_url(email, size) }))
  end
end
