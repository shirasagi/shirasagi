class Event::Page
  include Cms::Page::Model
  include Cms::Addon::Meta
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Cms::Addon::Body
  include Cms::Addon::File
  include Event::Addon::Body
  include Event::Addon::AdditionalInfo
  include Event::Addon::Category::Category
  include Event::Addon::Date
  include Workflow::Addon::Approver

  set_permission_name "event_pages"

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "event/page") }

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}/#{id}.html" : "#{id}.html"
    end
end
