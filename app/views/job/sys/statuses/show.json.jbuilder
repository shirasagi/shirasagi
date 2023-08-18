if job_stucked?
  json.status "stucked"
  json.notice do
    json.notices t('job.job_stucked.notice')
  end
else
  json.status "ok"
end
json.active_job do
  json.queue_adapter Rails.application.config.active_job.queue_adapter
end
json.job do
  json.mode Job::Service.config.mode
  json.polling_queues Job::Service.config.polling.queues
end
if @item
  json.item do
    json.name @item.name
    json.current_count @item.current_count
    json.updated @item.updated
  end
end
