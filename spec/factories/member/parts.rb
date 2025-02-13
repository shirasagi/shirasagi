FactoryBot.define do
  factory :member_part_login, class: Member::Part::Login, traits: [:cms_part] do
    route { "member/login" }
  end

  factory :member_part_photo_search, class: Member::Part::PhotoSearch, traits: [:cms_part] do
    route { "member/photo_search" }
  end

  factory :member_part_bookmark, class: Member::Part::Bookmark, traits: [:cms_part] do
    route { "member/bookmark" }
    # 本パーツには親フォルダー "member/bookmark" が必要
    cur_node { create :member_node_bookmark, cur_site: cur_site }

    after(:create) do |part|
      # そして、サイト内のどこかにフォルダー "member/login" が必要
      if Member::Node::Login.site(part.cur_site).blank?
        create(:member_node_login, cur_site: part.cur_site)
      end
    end
  end

  factory :member_part_blog_page, class: Member::Part::BlogPage, traits: [:cms_part] do
    route { "member/blog_page" }
  end

  factory :member_part_photo, class: Member::Part::Photo, traits: [:cms_part] do
    route { "member/photo" }
  end

  factory :member_part_photo_slide, class: Member::Part::PhotoSlide, traits: [:cms_part] do
    route { "member/photo_slide" }
  end

  factory :member_part_invited_group, class: Member::Part::InvitedGroup, traits: [:cms_part] do
    route { "member/invited_group" }
  end
end
