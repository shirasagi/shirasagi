FactoryBot.define do
  factory :gws_survey_form, class: Gws::Survey::Form do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "form-#{unique_id}" }
    description { Array.new(2) { "description-#{unique_id}" }.join("\r\n") }
    anonymous_state { %w(disabled enabled).sample }
    file_state { %w(closed public).sample }
    file_edit_state { %w(disabled enabled enabled_until_due_date).sample }
    due_date { Time.zone.now.beginning_of_day + rand(7).days }
  end
end
