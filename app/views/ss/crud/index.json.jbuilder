json.array!(@items) do |item|
  json.extract! *([item] + @model.fields.keys.map { |m| m.to_sym })
  json.url item.try(:full_url)
  json.path url_for(action: :show, id: item, format: :json)
  format_json_datetime(json, item)
  decorate_with_relations(json, item)
end
