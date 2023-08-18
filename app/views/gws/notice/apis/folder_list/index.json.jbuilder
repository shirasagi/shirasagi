json.items do
  json.array!(@items) do |item|
    json.name item.name.split('/').last
    json.filename item.name
    json.order item.order
    json.depth item.depth
    url = if @cur_mode == 'editable'
            gws_notice_editables_path(folder_id: item.id)
          elsif @cur_mode == 'readable'
            gws_notice_readables_path(folder_id: item.id)
          elsif @cur_mode == 'calendar'
            gws_notice_calendars_path(folder_id: item.id)
          end
    json.url url if url
    json.tree_url gws_notice_apis_folder_list_path(folder_id: item.id)
    json.is_current @cur_folder && @cur_folder.id == item.id
    json.is_parent @cur_folder && @cur_folder.name.start_with?("#{item.name}/")
  end
end
