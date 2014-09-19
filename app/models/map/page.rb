# coding: utf-8
class Map::Page
  include Cms::Page::Model
  include Cms::Addon::Meta
  include Cms::Addon::Body
  include Cms::Addon::File
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Category::Addon::Category
  include Event::Addon::Date
  include Workflow::Addon::Approver
  include Map::Addon::Page

  #set_permission_name "map_pages"
  set_permission_name "article_pages"

  default_scope ->{ where(route: "map/page") }

  before_save :seq_filename, if: ->{ basename.blank? }

#  public
#    def set_points(array)
#      map_points = []
#      array.each do |point|
#        if point[:loc].present?
#          map_points << point
#        end
#      end
#    end

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
