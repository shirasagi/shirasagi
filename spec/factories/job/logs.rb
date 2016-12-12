FactoryGirl.define do
  factory :job_log, class: Job::Log do
    transient do
      job nil
    end

    site_id { job.site_id }
    user_id { job.user_id }
    job_id { job.id }
    pool { job.pool }
    class_name { job.class_name }
    args { job.args }
    priority { job.priority }
    at { job.at }
  end

  trait :job_log_running do
    state Job::Log::STATE_RUNNING
    started { Time.zone.now }
    log { "Job Started" }
  end

  trait :job_log_completed do
    state Job::Log::STATE_COMPLETED
    started { 10.minutes.ago }
    closed { Time.zone.now }
    log { [ "Job Started", "Job Completed" ].join("\n") }
  end

  trait :job_log_failed do
    state Job::Log::STATE_FAILED
    started { 10.minutes.ago }
    closed { Time.zone.now }
    log { [ "Job Started", "Job Failed" ].join("\n") }
  end
end
