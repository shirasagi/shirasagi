# coding: utf-8
class Facility::Page
  include Cms::Page::Model
  include Cms::Addon::Meta
  include Facility::Addon::Body
  include Facility::Addon::File
  include Cms::Addon::Release
  include Facility::Addon::Location::Category
  include Facility::Addon::Type::Category
  include Facility::Addon::Use::Category
  #include Event::Addon::Date
  include Workflow::Addon::Approver
  include Map::Addon::Page

  #set_permission_name "facility_pages"
  set_permission_name "article_pages"

  default_scope ->{ where(route: "facility/page") }

  before_save :seq_filename, if: ->{ basename.blank? }

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
