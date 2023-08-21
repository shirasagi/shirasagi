FactoryBot.define do
  factory :gws_report_file, class: Gws::Report::File do
    cur_site { gws_site }
    cur_user { gws_user }

    state { %w(public closed).sample }
    name { "name-#{unique_id}" }
  end
end
