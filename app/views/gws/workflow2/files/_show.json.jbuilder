@item_reject_list ||= %w(form_id file_ids workflow_approvers).freeze
@column_value_reject_list ||= %w(_id column_id file_ids).freeze
@string_max_length ||= 255
@text_max_length ||= 10_000

json.extract! item, *@model.fields.keys.reject { |m| @item_reject_list.include?(m) }

json.user_rk_uid item.try(:user).try(:rk_uid)
json.url item.try(:full_url)
json.path url_for(action: :show, id: item, format: :json) rescue nil

json.workflow_approvers do
  json.array! item.workflow_approvers do |approver|
    json.extract! approver, *approver.keys
    user_id = approver[:user_id]
    if user_id
      user = Gws::User.find(user_id)
      group = user.gws_main_group(@cur_site)
      json.user jsonize_user(user)
      json.section jsonize_section(group) if group
    end
  end
end

format_json_datetime(json, item)
decorate_with_relations(json, item)

item.form.try do |form|
  json.form do
    json.id form.id.to_s
    json.name item.form.name
  end

  json.column_values do
    json.array! item.column_values.order_by(order: 1, name: 1) do |column_value|
      if value = column_value.send(:value)
        if column_value.is_a?(Gws::Column::Value::TextArea)
          value = truncate(value, length: @text_max_length)
        else
          value = truncate(value, length: @string_max_length)
        end
      end

      fields = column_value.class.fields
      field_names = fields.keys.reject { |m| @column_value_reject_list.include?(m) }
      field_names.each do |field_name|
        if fields[field_name].localized?
          name = field_name.start_with?("i18n_") ? field_name[5..-1] : field_name
          translations = column_value.send("#{field_name}_translations")
          json.set! name, translations[I18n.default_locale]
          SS.locales_in_order.each do |lang|
            next if translations[lang].blank?
            json.set! "#{name}_#{lang}", translations[lang]
          end
        elsif field_name == "value"
          json.set! field_name, value
        else
          json.set! field_name, column_value.send(field_name)
        end
      end
      decorate_with_relations(json, column_value)
    end
  end
end
