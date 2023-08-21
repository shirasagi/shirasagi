FactoryBot.define do
  factory :gws_history_model, class: Gws::History do
    session_id { unique_id }
    request_id { unique_id }
    severity { %w(error warn info notice).sample }
    name { unique_id }
    mode { %w(create update delete).sample }
    model { 'Gws::Schedule::Plan'.underscore }
    item_id { unique_id }
  end

  factory :gws_history_controller, class: Gws::History do
    session_id { unique_id }
    request_id { unique_id }
    severity { %w(error warn info notice).sample }
    name { unique_id }
    controller { Gws::Schedule::PlansController.controller_path }
    path { "/.s1/plans/#{unique_id}" }
    action { %w(index show new create edit update delete destroy).sample }
    message { unique_id }
  end

  factory :gws_history_job, class: Gws::History do
    session_id { unique_id }
    request_id { unique_id }
    severity { %w(error warn info notice).sample }
    name { unique_id }
    job { Gws::Reminder::NotificationJob.name.underscore }
    action { 'perform' }
    message { unique_id }
  end
end
