FactoryBot.define do
  factory :cms_transaction_unit_command, class: Cms::Transaction::Unit::Command do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id }
  end

  factory :cms_transaction_unit_generation, class: Cms::Transaction::Unit::Generation do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id }
  end

  factory :cms_transaction_unit_publisher, class: Cms::Transaction::Unit::Publisher do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id }
  end
end
