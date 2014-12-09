class Ezine::Page
  include Cms::Page::Model
  include Cms::Addon::Release

  seqid :id
  field :route, type: String, default: ->{ "ezine/page" }
  field :name, type: String
  field :html, type: String, default: ""
  field :text, type: String, default: ""
  field :results, type: Array

  permit_params :id, :route, :name, :html, :text, :results

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "ezine/page") }

  private
    def validate_filename
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
