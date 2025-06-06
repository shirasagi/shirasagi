FactoryBot.define do
  factory :gws_affair2_leave_record, class: Gws::Affair2::Leave::Record do
    cur_site { gws_site }
    cur_user { gws_user }
  end
end
