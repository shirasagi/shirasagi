FactoryBot.define do
  factory :sys_postal_code, class: Sys::PostalCode do
    code { unique_id }
    prefecture { unique_id }
  end
end
