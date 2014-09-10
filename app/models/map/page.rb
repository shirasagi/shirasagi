# coding: utf-8
class Map::Page
  include Cms::Page::Model

  default_scope ->{ where(route: "map/page") }
  set_permission_name "article_pages"

  before_save :seq_filename, if: ->{ basename.blank? }

  public
    def set_points(array)
      map_points = []
      array.each do |point|
        if point[:loc].present?
          map_points << point
        end
      end
#     raise self.class.permitted_fields.to_s
      raise map_points.to_s
    end

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end

  class << self
    def inherit_addons(mod, opts={})
      except = opts[:except] ? [opts[:except]].flatten : []

      names = addons.map {|m| m.klass }
      mod.addons.each do |addon|
        next if except.include?(addon.instance_variable_get(:@name))
        include addon.klass unless names.include?(addon.klass)
      end

      mod.instance_eval do
        def addon(*args)
          Map::Page.addon *args
          super
        end
      end
    end
  end
end
