FactoryBot.define do
  factory :service_account, class: Service::Account do
    account { "text-#{unique_id}" }
    in_password { "text-#{unique_id}" }
    name { "text-#{unique_id}" }
  end

  factory :service_account_admin, class: Service::Account do
    account { "text-#{unique_id}" }
    in_password { "text-#{unique_id}" }
    name { "text-#{unique_id}" }
    roles ['administrator']
  end
end
