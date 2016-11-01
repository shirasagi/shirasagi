json.extract! *([@item] + @model.fields.keys.map {|m| m.to_sym })
format_json_datetime(json, @item)
decorate_with_relations(json, @item)
