FactoryGirl.define do
  factory :sys_group, class: Sys::Group do
    name { unique_id }
  end
end
