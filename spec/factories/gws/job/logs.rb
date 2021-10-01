FactoryBot.define do
  factory :gws_job_log, class: Gws::Job::Log do
    transient do
      job { nil }
    end

    group_id { job.site_id }
    user_id { job.user_id }
    job_id { job.job_id }
    state { 'stop' }
    pool { job.queue_name }
    class_name { job.class.name }
    args { job.arguments }
    # priority { job.priority }
    # at { job.at }
  end

  trait :gws_job_log_running do
    state { Job::Log::STATE_RUNNING }
    started { Time.zone.now }
    logs { [ "Job Started" ] }
  end

  trait :gws_job_log_completed do
    state { Job::Log::STATE_COMPLETED }
    started { 10.minutes.ago }
    closed { Time.zone.now }
    logs { [ "Job Started", "Job Completed" ] }
  end

  trait :gws_job_log_failed do
    state { Job::Log::STATE_FAILED }
    started { 10.minutes.ago }
    closed { Time.zone.now }
    logs { [ "Job Started", "Job Failed" ] }
  end
end
