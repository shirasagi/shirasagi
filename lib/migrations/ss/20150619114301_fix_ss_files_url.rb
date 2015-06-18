class SS::Migration20150619114301
  def change
    Cms::Page.all.each { |item| replace_fs_urls(item) }
    Cms::Layout.all.each { |item| replace_fs_urls(item) }
    Cms::Part.all.each { |item| replace_fs_urls(item) }
  end

  def replace_fs_urls(item)
    if item.respond_to?(:html) && item.html.present?
      item.set(html: gsub_urls(item.html))
    end

    if item.respond_to?(:upper_html) && item.upper_html.present?
      item.set(upper_html: gsub_urls(item.upper_html))
    end

    if item.respond_to?(:lower_html) && item.lower_html.present?
      item.set(lower_html: gsub_urls(item.lower_html))
    end
  end

  def gsub_urls(html)
    html.gsub(%r{(="/fs/)(\d+)(/[\w\-]+\.[\w\-.]+")}) do
      head = $1
      id   = $2
      tail = $3
      "#{head}#{id.split("").join("/")}/_#{tail}"
    end
  end
end
