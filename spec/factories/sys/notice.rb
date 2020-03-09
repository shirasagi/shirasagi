FactoryBot.define do
  factory :sys_notice, class: Sys::Notice do
    name { "name-#{unique_id}" }
    html { "<p>#{unique_id}</p>" }
  end
end
