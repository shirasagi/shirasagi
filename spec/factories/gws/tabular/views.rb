FactoryBot.define do
  trait :gws_tabular_view_base do
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
    state { %w(public closed).sample }
    order { rand(0..500) }
    default_state { %w(disabled enabled).sample }
    memo { Array.new(2) { "memo-#{unique_id}" }.join("\n") }
  end

  trait :gws_tabular_view_readonly do
    authoring_permissions { %w(read) }
  end

  trait :gws_tabular_view_editable do
    authoring_permissions { Gws::Tabular::View::Base::AUTHORING_PERMISSIONS }
  end

  factory :gws_tabular_view_list, class: Gws::Tabular::View::List, traits: [:gws_tabular_view_base]
  factory :gws_tabular_view_liquid, class: Gws::Tabular::View::Liquid, traits: [:gws_tabular_view_base]

  factory :gws_tabular_view_liquid_with_pagination, class: Gws::Tabular::View::Liquid, traits: [:gws_tabular_view_base] do
    template_html do
      <<~HTML
        <div class="pagination upper">{% ss_pagination %}</div>

        <div class="list">
          {% for item in items %}
          <a href="{{ item | show_url }}" class="list-item" data-id="{{ item.id }}">
            <span class="list-item-name">{{ item.values["name"] }}</span>
            <time class="list-item-updated" datetime="{{ item.updated }}">{{ item.updated | ss_item: "iso" }}</span>
          </a>
          {% endfor %}
        </div>

        <div class="pagination lower">{% ss_pagination %}</div>
      HTML
    end
  end
end
