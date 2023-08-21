FactoryBot.define do
  factory :cms_form, class: Cms::Form do
    cur_user { cms_user }
    name { unique_id }
    order { rand(999) }
    state { %w(public closed).sample }
    sub_type { %w(static entry).sample }
    html { unique_id }
  end
end
