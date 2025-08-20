FactoryBot.define do
  factory :cms_form, class: Cms::Form do
    cur_user { cms_user }
    name { unique_id }
    order { rand(999) }
    state { %w(public closed).sample }
    sub_type { %w(static entry).sample }
    html do
      <<~HTML
        <header>Name: #{name}</header>
        {% for value in values -%}
          <div data-name="{{ value.name }}" data-type="{{ value.type }}">{{ value }}</div>
        {% endfor -%}
      HTML
    end
  end
end
