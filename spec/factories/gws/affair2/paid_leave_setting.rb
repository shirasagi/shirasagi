FactoryBot.define do
  factory :gws_affair2_paid_leave_setting, class: Gws::Affair2::PaidLeaveSetting do
    cur_site { gws_site }
    cur_user { gws_user }
    name { unique_id }
    carryover_minutes { 465 * 10 }
    additional_minutes { 465 * 10 }
  end
end
