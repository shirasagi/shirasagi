FactoryGirl.define do
  factory :history_log, class: History::Log, traits: [:ss_site, :ss_user] do
    url "/path/to"
    controller "module/controller"
    action "create"
    target_id 1
    target_class "Class"
  end
end
