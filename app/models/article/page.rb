class Article::Page
  include Cms::Model::Page
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::Meta
  include Cms::Addon::Body
  include Cms::Addon::File
  include Category::Addon::Category
  include Event::Addon::Date
  include Map::Addon::Page
  include Contact::Addon::Page
  include Cms::Addon::RelatedPage
  include Cms::Addon::ParentCrumb
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "article_pages"

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "article/page") }

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
