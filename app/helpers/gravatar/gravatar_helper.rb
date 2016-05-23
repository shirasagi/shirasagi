module Gravatar::GravatarHelper
  def gravatar_image_url(email, options = {})
    # we don't know any other options except :size and :default
    email_md5 = Digest::MD5.hexdigest(email)
    url = "https://gravatar.com/avatar/#{email_md5}"

    options = options.symbolize_keys
    query = {}
    query[:s] = options[:size] if options[:size].present?
    query[:d] = options[:default] if options[:default].present?
    query.present? ? "#{url}?#{query.to_query}" : url
  end

  def gravatar_image_tag(email, gravatar_options = {}, html_options = {})
    html_options = html_options.symbolize_keys
    tag(:img, html_options.merge({ src: gravatar_image_url(email, gravatar_options) }))
  end
end
