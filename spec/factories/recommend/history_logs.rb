FactoryBot.define do
  factory :recommend_history_log, class: Recommend::History::Log do
    cur_site { cms_site }
    token { "token-#{unique_id}" }
    path { "/#{unique_id}.html" }
    access_url { "http://example.jp#{path}" }
    target_id { rand(1..10) }
    target_class { %w(Cms::Page Article::Page Sitemap::Page Faq::Page).sample }
    remote_addr { "10.0.0.#{rand(0..255)}" }
    user_agent { "ua-#{unique_id}" }
  end
end
