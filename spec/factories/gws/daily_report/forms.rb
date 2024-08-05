FactoryBot.define do
  factory :gws_daily_report_form, class: Gws::DailyReport::Form do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    year { cur_site.fiscal_year }
    order { rand(999) }
    memo { Array.new(2) { "memo-#{unique_id}" }.join("\n") }
    daily_report_group { cur_site }
  end
end
