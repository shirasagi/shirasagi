FactoryGirl.define do
  factory :member_node_login, class: Member::Node::Login, traits: [:cms_node] do
    transient do
      site nil
    end

    site_id { site.present? ? site.id : cms_site.id }
    route "member/login"
    filename { SS.config.oauth.prefix_path.sub(/^\//, '') || "auth" }
    twitter_oauth "enabled"
    twitter_client_id unique_id.to_s
    twitter_client_secret unique_id.to_s
    facebook_oauth "enabled"
    facebook_client_id unique_id.to_s
    facebook_client_secret unique_id.to_s
  end
end
