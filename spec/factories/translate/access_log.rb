FactoryBot.define do
  factory :translate_access_log, class: Translate::AccessLog, traits: [:translate_lang] do
    cur_site { cms_site }
    path { unique_id }
    remote_addr { "10.0.0.#{rand(0..255)}" }
    user_agent { "ua-#{unique_id}" }
  end
end
