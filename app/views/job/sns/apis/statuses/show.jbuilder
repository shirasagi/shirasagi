json.type @item.class.name
json.id @item.id
if @item.is_a?(Job::Task)
  json.job_id @item.name
else
  json.job_id @item.job_id
  json.started(@item.started.try { |time| time.iso8601 })
  json.closed(@item.closed.try { |time| time.iso8601 })
  json.logs @item.head_logs
end
json.state @item.state
json.updated(@item.updated.try { |time| time.iso8601 })
