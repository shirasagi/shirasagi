if @item.present?
  json.width @item.width
  json.time @item.time
  json.file_ids @item.file_ids

  json.files do
    json.array! @item.files do |file|
      json.name file.name
      json.filename file.filename
      json.size file.size
      json.content_type file.content_type
      json.link_url file.link_url
      json.url file.url
      json.full_url "#{@url}#{file.url}"
    end
  end
end
