module GravatarHelper
  def gravatar_image_url(email, size = 150, default: nil)
    url = "https://gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}?s=#{size}"
    default.present? ? "#{url}&d=#{CGI.escape(default)}" : url
  end

  def gravatar_image_tag(email, size = 150, options = {})
    default = options.delete :default
    tag(:img, options.merge({ src: gravatar_image_url(email, size, default: default) }))
  end
end
