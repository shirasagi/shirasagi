FactoryGirl.define do
  factory :history_log, class: History::Log do
    url "/path/to"
    controller "module/controller"
    action "create"
    target_id 1
    target_class "Class"
  end
end
