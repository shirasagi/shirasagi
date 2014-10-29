class Faq::Page
  include Cms::Page::Model
  include Cms::Addon::Meta
  include Cms::Addon::Body
  include Cms::Addon::File
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Category::Addon::Category
  include Event::Addon::Date
  include Workflow::Addon::Approver
  include Faq::Addon::Question
  include Faq::Reference::Question
  include Contact::Addon::Page
  include History::Addon::Backup

  set_permission_name "faq_pages"

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "faq/page") }

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
