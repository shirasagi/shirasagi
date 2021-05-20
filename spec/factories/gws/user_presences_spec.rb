FactoryBot.define do
  factory :gws_user_presence, class: Gws::UserPresence do
    state { "available" }
    plan { unique_id }
    memo { unique_id }
  end
end
