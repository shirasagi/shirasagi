FactoryBot.define do
  factory :gws_affair2_leave_file, class: Gws::Affair2::Leave::File do
    cur_site { gws_site }
    name { unique_id }
  end
end
