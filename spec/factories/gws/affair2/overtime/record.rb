FactoryBot.define do
  factory :gws_affair2_overtime_record, class: Gws::Affair2::Overtime::Record do
    cur_site { gws_site }
    cur_user { gws_user }
  end
end
