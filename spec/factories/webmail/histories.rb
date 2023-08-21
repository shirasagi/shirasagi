FactoryBot.define do
  factory :webmail_history_model, class: Webmail::History do
    session_id { unique_id }
    request_id { unique_id }
    severity { %w(error warn info notice).sample }
    name { unique_id }
    mode { %w(create update delete).sample }
    model { 'Webmail::User'.underscore }
    item_id { unique_id }
  end
end
