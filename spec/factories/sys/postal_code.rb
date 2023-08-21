FactoryBot.define do
  factory :sys_postal_code, class: Sys::PostalCode do
    code { Array.new(7) { rand(0..9) }.join }
    prefecture { unique_id }
  end
end
