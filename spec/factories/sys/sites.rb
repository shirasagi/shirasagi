FactoryGirl.define do
  factory :sys_site, class: Sys::Site do
    name "sys"
    host "test-sys"
    domains "test-sys.com"
    #group_id 1
  end
end
