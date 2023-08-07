puts "# source_cleaner_templates"

def save_source_cleaner_template(data)
  puts data[:name]
  cond = { site_id: @site.id, name: data[:name] }

  item = Cms::SourceCleanerTemplate.find_or_create_by cond
  puts item.errors.full_messages unless item.update data
  item
end

save_source_cleaner_template name: "<p>&nbsp;</p>", target_type: "string", target_value: "<p>&nbsp;</p>",
  action_type: "remove", state: "public", order: 10
save_source_cleaner_template name: "width", target_type: "attribute", target_value: "width",
  action_type: "remove", state: "public", order: 20
save_source_cleaner_template name: "height", target_type: "attribute", target_value: "height",
  action_type: "remove", state: "public", order: 30
save_source_cleaner_template name: "cellpadding", target_type: "attribute", target_value: "cellpadding",
  action_type: "remove", state: "public", order: 40
save_source_cleaner_template name: "cellspacing", target_type: "attribute", target_value: "cellspacing",
  action_type: "remove", state: "public", order: 50
save_source_cleaner_template name: "border", target_type: "attribute", target_value: "border",
  action_type: "remove", state: "public", order: 60
save_source_cleaner_template name: "style", target_type: "attribute", target_value: "style",
  action_type: "remove", state: "public", order: 100
