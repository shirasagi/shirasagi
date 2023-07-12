json.items do
  json.array!(@items) do |item|
    json.name item.name.split('/').last
    json.filename item.name
    json.order item.order
    json.depth item.depth
    json.url gws_bookmark_items_path(folder_id: item.id)
    json.tree_url gws_bookmark_apis_folder_list_path(folder_id: item.id)
    json.is_current @folder && @folder.id == item.id
    json.is_parent true
  end
end
