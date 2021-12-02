class Member::BlogPage
  include Cms::Model::Page
  include Cms::Reference::Member
  include Workflow::Addon::Approver
  include Member::Addon::Blog::Body
  include Member::Addon::File
  include Member::Addon::Blog::Genre
  include Member::Addon::Blog::Location
  include Cms::Addon::GroupPermission
  include Cms::Addon::Release

  set_permission_name "member_blogs"

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "member/blog_page") }

  def file_previewable?(file, site:, user:, member:)
    return true if super

    return true if member.present? && member_id == member.id

    false
  end

  private

  def serve_static_file?
    false
  end

  def validate_filename
    (@basename && @basename.blank?) ? nil : super
  end

  def seq_filename
    self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
  end

  class << self
    def search(params = {})
      criteria = super(params)
      return criteria if params.blank?

      if params[:g].present?
        criteria = criteria.in(genres: params[:g])
      end
      criteria
    end
  end
end
