json.array!(@items) do |item|
  #json.extract! item, :name, :price
  #json.url item_url(item, format: :json)
  json.extract! *([item] + @model.fields.keys.map {|m| m.to_sym })
  json.url url_for(action: :show, id: item, format: :json)
end
