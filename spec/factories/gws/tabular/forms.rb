FactoryBot.define do
  factory :gws_tabular_form, class: Gws::Tabular::Form do
    transient do
      name { nil }
    end

    cur_site { gws_site }
    cur_user { gws_user }

    i18n_name_translations do
      if name
        { I18n.default_locale => name }.with_indifferent_access
      else
        i18n_translations(prefix: "form")
      end
    end
    state { %w(public publishing closed).sample }
    order { rand(0..500) }
    memo { Array.new(2) { "memo-#{unique_id}" }.join("\n") }
    revision { rand(0..500) }
  end
end
