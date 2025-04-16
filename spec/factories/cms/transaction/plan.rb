FactoryBot.define do
  factory :cms_transaction_plan, class: Cms::Transaction::Plan do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id }
  end
end
