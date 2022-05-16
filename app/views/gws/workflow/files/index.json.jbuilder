item_reject_list = %w(form_id file_ids workflow_approvers).freeze
column_value_reject_list = %w(_id column_id file_ids).freeze

json.array!(@items) do |item|
  json.extract! item, *@model.fields.keys.reject { |m| item_reject_list.include?(m) }
  json.workflow_approvers do
    json.array! item.workflow_approvers do |approver|
      json.extract! approver, *approver.keys
      user_id = approver[:user_id]
      if user_id
        user = Gws::User.find(user_id)
        json.user jsonize_user(user)
      end
    end
  end
  json.url item.try(:full_url)
  json.path url_for(action: :show, id: item, format: :json) rescue nil
  format_json_datetime(json, item)
  decorate_with_relations(json, item)
  if item.form.present?
    json.form do
      json.id item.form.id
      json.name item.form.name
    end

    json.column_values do
      json.array! item.column_values do |column_value|
        json.extract! column_value, *column_value.class.fields.keys.reject { |m| column_value_reject_list.include?(m) }
        decorate_with_relations(json, column_value)
      end
    end
  end
end
