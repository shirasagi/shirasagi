FactoryBot.define do
  factory :ss_notification, class: SS::Notification do
    subject { unique_id }
    text { unique_id }
    format { "text" }
    send_date { Time.zone.now.beginning_of_minute - 5.days }
    url { "/#{unique_id}" }
    group_id { ss_group.id }
    user_id { ss_user.id }
    member_ids { [ ss_user.id ] }
  end
end
