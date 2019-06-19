FactoryBot.define do
  factory :sys_notice, class: Sys::Notice do
    name { "name-#{unique_id}" }
  end
end
