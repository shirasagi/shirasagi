# coding: utf-8
class Event::Page
  include Cms::Page::Model
  
  default_scope ->{ where(route: "event/page") }
  
  before_save :seq_filename, if: ->{ basename.blank? }
  
  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end
    
    def seq_filename
      self.filename = dirname ? "#{dirname}/#{id}.html" : "#{id}.html"
    end
end
