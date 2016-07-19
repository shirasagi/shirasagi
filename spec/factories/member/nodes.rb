FactoryGirl.define do
  factory :member_node_login, class: Member::Node::Login, traits: [:cms_node] do
    cur_site { cms_site }
    route "member/login"
    filename { SS.config.oauth.prefix_path.sub(/^\//, '') || "auth" }
    twitter_oauth "enabled"
    twitter_client_id unique_id.to_s
    twitter_client_secret unique_id.to_s
    facebook_oauth "enabled"
    facebook_client_id unique_id.to_s
    facebook_client_secret unique_id.to_s
  end

  factory :member_node_mypage, class: Member::Node::Mypage, traits: [:cms_node] do
    route "member/mypage"
  end

  factory :member_node_my_profile, class: Member::Node::MyProfile, traits: [:cms_node] do
    route "member/my_profile"
  end

  factory :member_node_my_blog, class: Member::Node::MyBlog, traits: [:cms_node] do
    route "member/my_blog"
  end

  factory :member_node_my_photo, class: Member::Node::MyPhoto, traits: [:cms_node] do
    route "member/my_photo"
  end

  factory :member_node_blog, class: Member::Node::Blog, traits: [:cms_node] do
    route "member/blog"
  end

  factory :member_node_blog_page, class: Member::Node::BlogPage, traits: [:cms_node] do
    route "member/blog_page"
  end

  factory :member_node_photo, class: Member::Node::Photo, traits: [:cms_node] do
    route "member/photo"
  end

  factory :member_node_photo_search, class: Member::Node::PhotoSearch, traits: [:cms_node] do
    route "member/photo_search"
  end

  factory :member_node_photo_spot, class: Member::Node::PhotoSpot, traits: [:cms_node] do
    route "member/photo_spot"
  end

  factory :member_node_photo_category, class: Member::Node::PhotoCategory, traits: [:cms_node] do
    route "member/photo_category"
  end

  factory :member_node_photo_location, class: Member::Node::PhotoLocation, traits: [:cms_node] do
    route "member/photo_location"
  end

  factory :member_node_registration, class: Member::Node::Registration, traits: [:cms_node] do
    route "member/registration"
  end

  factory :member_node_my_anpi_post, class: Member::Node::MyAnpiPost, traits: [:cms_node] do
    route "member/my_anpi_post"
  end

  factory :member_node_my_group, class: Member::Node::MyGroup, traits: [:cms_node] do
    route "member/my_group"
    sender_name { unique_id }
    sender_email { "#{sender_name}@example.jp" }
  end
end
