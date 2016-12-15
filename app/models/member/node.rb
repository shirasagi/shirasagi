module Member::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^member\//) }
  end

  class Login
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Member::Addon::Redirection
    include Member::Addon::FormAuth
    include Member::Addon::TwitterOauth
    include Member::Addon::FacebookOauth
    include Member::Addon::YahooJpOauth
    include Member::Addon::GoogleOauth
    include Member::Addon::GithubOauth
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/login") }
  end

  class Mypage
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Html
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/mypage") }

    def children
      Member::Node::Base.and_public.
        where(site_id: site_id, filename: /^#{filename}\//, depth: depth + 1).
        order_by(order: 1)
    end
  end

  class MyProfile
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Member::Addon::Registration::RequiredFields
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/my_profile") }
  end

  class Registration
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Member::Addon::Registration::SenderAddress
    include Member::Addon::Registration::Confirmation
    include Member::Addon::Registration::Reply
    include Member::Addon::Registration::ResetPasswordMail
    include Member::Addon::Registration::RequiredFields
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/registration") }
  end

  class MyBlog
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/my_blog") }

    def setting_url
      "#{url}setting/"
    end

    def blog(member)
      Member::Blog.where(site_id: site.id, member_id: member.id).first
    end
  end

  class MyPhoto
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/my_photo") }
  end

  class Blog
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Member::Addon::Blog::BlogSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/blog") }

    def sort_hash
      return { created: -1 } if sort.blank?
      super
    end

    def layout_options
      Member::BlogLayout.where(filename: /^#{filename}\//).
        map { |item| [item.name, item.id] }
    end
  end

  class BlogPage
    include Cms::Model::Node
    include Cms::Reference::Member
    include Member::Addon::Blog::PageSetting
    include Cms::Addon::PageList
    include Cms::Addon::GroupPermission

    set_permission_name "member_blogs"

    default_scope ->{ where(route: "member/blog_page") }

    before_validation ->{ self.page_layout = layout }

    def pages
      Member::BlogPage.where(filename: /^#{filename}\//, depth: depth + 1).and_public
    end
  end

  class BlogPageLocation
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/blog_page_location") }

    def sort_hash
      return { created: -1 } if sort.blank?
      super
    end

    def condition_hash
      cond = []
      cids = []

      cids << id
      conditions.each do |url|
        node = Cms::Node.filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :blog_page_location_ids.in => cids } if cids.present?

      { '$or' => cond }
    end
  end

  class Photo
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Member::Addon::Photo::LicenseSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo") }
  end

  class PhotoSearch
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo_search") }
  end

  class PhotoSpot
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo_spot") }
  end

  class PhotoCategory
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo_category") }

    def condition_hash
      cond = []
      cids = []

      cids << id
      conditions.each do |url|
        node = Cms::Node.filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :photo_category_ids.in => cids } if cids.present?

      { '$or' => cond }
    end
  end

  class PhotoLocation
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo_location") }

    def condition_hash
      cond = []
      cids = []

      cids << id
      conditions.each do |url|
        node = Cms::Node.filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :photo_location_ids.in => cids } if cids.present?

      { '$or' => cond }
    end
  end

  class MyAnpiPost
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Board::Addon::AnpiPostSetting
    include Board::Addon::GooglePersonFinderSetting
    include Board::Addon::MapSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/my_anpi_post") }
  end

  class MyGroup
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Member::Addon::Registration::SenderAddress
    include Member::Addon::GroupInvitationSetting
    include Member::Addon::MemberInvitationSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/my_group") }
  end
end
