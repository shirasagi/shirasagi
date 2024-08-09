FactoryBot.define do
  factory :gws_workflow2_form_application, class: Gws::Workflow2::Form::Application do
    transient do
      name { nil }
    end

    cur_site { gws_site }
    cur_user { gws_user }

    i18n_name_translations do
      if name
        { I18n.default_locale => name }.with_indifferent_access
      else
        i18n_translations(prefix: "application")
      end
    end
    order { rand(100 ) }
    state { %w(closed public).sample }
    agent_state { %w(disabled enabled).sample }
    i18n_description_translations { i18n_translations prefix: "description", count: 2, join: "\n" }
    memo { "memo-#{unique_id}" }
    readable_setting_range { "public" }
  end
end
