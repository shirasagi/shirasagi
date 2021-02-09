item ||= @item
json.extract! item, *(item.class.fields.keys.map { |m| m.to_sym })

if item.state.present?
  json.state_label t("job.state.#{item.state}", default: nil)
end

head_logs = params[:head_logs].numeric? ? params[:head_logs].to_i : nil
head_logs ||= SS.config.job.head_logs || 1_000
json.head_logs item.head_logs(head_logs)
