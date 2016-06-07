module Member::Part
  class Login
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/login") }
  end

  class BlogPage
    include Cms::Model::Part
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/blog_page") }

    template_variable_handler :contributor, :template_variable_handler_contributor

    def condition_hash(opts = {})
      cond = []
      cids = []
      cond_url = []

      cond << { filename: /^#{parent.filename}\// }
      #cids << id
      #cond_url = conditions
      { '$or' => cond }
    end

    private
      def template_variable_handler_contributor(name, item)
        item.contributor
      end
  end

  class Photo
    include Cms::Model::Part
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo") }
  end

  class PhotoSearch
    include Cms::Model::Part
    include KeyVisual::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo_search") }
  end

  class PhotoSlide
    include Cms::Model::Part
    include KeyVisual::Addon::PageList
    include Member::Addon::Photo::Slide
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/photo_slide") }
  end

  class InvitedGroup
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "member/invited_group") }
  end
end
