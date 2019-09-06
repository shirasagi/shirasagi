FactoryBot.define do
  factory :sys_prefecture_code, class: Sys::PrefectureCode do
    code { unique_id }
    prefecture { unique_id }
  end
end
