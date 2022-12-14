FactoryBot.define do
  factory :gws_affair_capital_year, class: Gws::Affair::CapitalYear do
    cur_site { gws_site }
    cur_user { gws_user }
    name { "令和2年" }
    code { 2020 }
    start_date { Time.zone.parse("2020/04/01") }
    close_date { Time.zone.parse("2021/03/31") }
  end
end
