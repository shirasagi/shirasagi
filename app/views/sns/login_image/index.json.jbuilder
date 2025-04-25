if @item.present?
  json.width @item.width
  json.time @item.time
  ad_links = @item.ad_links.where(state: "show").to_a.select { _1.file.present? && _1.file.image? }
  json.file_ids ad_links.map { _1.file.id }

  json.files do
    json.array! ad_links do |ad_link|
      json.name ad_link.name.presence || ad_link.file.name
      json.filename ad_link.file.filename
      json.size ad_link.file.size
      json.content_type ad_link.file.content_type
      json.link_url ad_link.url
      json.url ad_link.file.url
      json.full_url "#{@url}#{ad_link.file.url}"
    end
  end
end
