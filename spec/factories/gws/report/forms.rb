FactoryBot.define do
  factory :gws_report_form, class: Gws::Report::Form do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    order { rand(999) }
    state { %w(public closed).sample }
  end
end
