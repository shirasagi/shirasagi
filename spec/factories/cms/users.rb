FactoryGirl.define do
  factory :cms_user, class: Cms::User do
    name "cms_user"
    email "cms@example.jp"
    in_password "pass"
    #cms_role_ids
  end
end
