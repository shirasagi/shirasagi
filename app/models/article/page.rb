# coding: utf-8
class Article::Page
  include Cms::Page::Model
  
  default_scope ->{ where(route: "article/page") }
  set_permission_name "article_pages"
  
  before_save :seq_filename, if: ->{ basename.blank? }
  
  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end
    
    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
    
  class << self
    def inherit_addons(mod)
      Article::Page.addon "cms/body"
      
      names = addons.map {|m| m.klass }
      mod.addons.each {|addon| include addon.klass unless names.include?(addon.klass) }
      mod.instance_eval do
        def addon(*args)
          Article::Page.addon *args
          super
        end
      end
    end
  end
end
