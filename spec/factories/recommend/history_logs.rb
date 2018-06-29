FactoryBot.define do
  factory :recommend_history_log, class: Recommend::History::Log do
    cur_site { cms_site }
    remote_addr "dummy"
    user_agent "dummy"
  end
end
