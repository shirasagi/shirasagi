FactoryGirl.define do
  factory :cms_user, class: Cms::User do
    transient do
      group nil
      role nil
    end

    name "cms_user"
    email "cms@example.jp"
    in_password "pass"

    after(:build) do |user, evaluator|
      if evaluator.group
        user.group_ids = [evaluator.group.id]
        user.accounts = [{uid: user.name, group_id: evaluator.group.id}]
      end
      if evaluator.role
        user.cms_role_ids = [evaluator.role.id]
      end
    end
  end
end
