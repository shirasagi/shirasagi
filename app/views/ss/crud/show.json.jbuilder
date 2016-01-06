#json.extract! @item, :name, :price, :created_at, :updated_at
json.extract! *([@item] + @model.fields.keys.map {|m| m.to_sym })
format_json_datetime(json, @item)
