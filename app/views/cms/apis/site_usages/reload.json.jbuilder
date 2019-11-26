json.usage_node_count @cur_site.usage_node_count
json.usage_page_count @cur_site.usage_page_count
json.usage_file_count @cur_site.usage_file_count
json.usage_db_size @cur_site.usage_db_size
json.usage_group_count @cur_site.usage_group_count
json.usage_user_count @cur_site.usage_user_count
json.usage_calculated_at @cur_site.usage_calculated_at

json.usage_node_count_html @cur_site.usage_node_count.try { |v| v.to_s(:delimited) } || '-'
json.usage_page_count_html @cur_site.usage_page_count.try { |v| v.to_s(:delimited) } || '-'
json.usage_file_count_html @cur_site.usage_file_count.try { |v| v.to_s(:delimited) } || '-'
json.usage_db_size_html @cur_site.usage_db_size.try { |v| v.to_s(:human_size) } || '-'
json.usage_group_count_html @cur_site.usage_group_count.try { |v| v.to_s(:delimited) } || '-'
json.usage_user_count_html @cur_site.usage_user_count.try { |v| v.to_s(:delimited) } || '-'
json.usage_calculated_at_html @cur_site.usage_calculated_at.try { |v| I18n.l(v) } || '-'
