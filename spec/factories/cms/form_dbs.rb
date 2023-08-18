FactoryBot.define do
  factory :cms_form_db, class: Cms::FormDb do
    cur_user { cms_user }
    name { unique_id }
    order { rand(999) }
  end
end
