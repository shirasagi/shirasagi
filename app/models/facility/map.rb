class Facility::Map
  include Cms::Page::Model
  include Cms::Addon::Meta
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Map::Addon::Page
  include Workflow::Addon::Approver

  default_scope ->{ where(route: "facility/map") }

  before_save :seq_filename, if: ->{ basename.blank? }

  private
    def validate_filename
      (@basename && @basename.blank?) ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
