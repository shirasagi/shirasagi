# coding: utf-8
class Facility::Image
  include Cms::Page::Model
  include Cms::Addon::Meta
  include Facility::Addon::Image

  #set_permission_name "facility_pages"
  set_permission_name "article_pages"

  default_scope ->{ where(route: "facility/image") }

  before_save :seq_filename, if: ->{ basename.blank? }

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
