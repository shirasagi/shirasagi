FactoryGirl.define do
  factory :rss_pub_sub_hubbub_verification_param, class: Rss::PubSubHubbub::VerificationParam do
    mode 'subscribe'
    topic 'http://www.web-tips.co.jp/docs/rss.xml'
    challenge { unique_id }
    lease_seconds 432_000
  end
end
