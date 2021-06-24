FactoryBot.define do
  factory :gws_staff_record_seating, class: Gws::StaffRecord::Seating do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    url { "/#{unique_id}/#{unique_id}.html" }
    remark { Array.new(2) { "remark-#{unique_id}" }.join("\n") }
    order { rand(1..100) }
  end
end
