# #json.extract! @item, :name, :price, :created_at, :updated_at
# json.extract! *([@item] + @model.fields.keys.map {|m| m.to_sym })
json._id @item._id
json.lock_owner @item.lock_owner.long_name
json.lock_owner_id @item.lock_owner_id
json.lock_until_epoch @item.lock_until.to_i
json.lock_until_pretty @item.lock_until.strftime("%Y/%m/%d %H:%M")
