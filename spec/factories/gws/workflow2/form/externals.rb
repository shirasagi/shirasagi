FactoryBot.define do
  factory :gws_workflow2_form_external, class: Gws::Workflow2::Form::External do
    transient do
      name { nil }
      url { nil }
    end

    cur_site { gws_site }
    cur_user { gws_user }

    i18n_name_translations do
      if name
        { I18n.default_locale => name }.with_indifferent_access
      else
        i18n_translations(prefix: "external")
      end
    end
    order { rand(100 ) }
    i18n_url_translations do
      if url
        { I18n.default_locale => url }.with_indifferent_access
      else
        I18n.available_locales.index_with { "/#{unique_id}/" }.with_indifferent_access
      end
    end
    i18n_description_translations { i18n_translations prefix: "description", count: 2, join: "\n" }
    memo { Array.new(2) { "memo-#{unique_id}" }.join("\n") }
    state { %w(public closed).sample }
  end
end
