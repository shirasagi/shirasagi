if @items.present?
  json.array! @items do |item|
    json.title item.name
    json.description item.description
    json.content item.html
  end
else
  json.array! []
end
