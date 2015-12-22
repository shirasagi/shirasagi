class Cms::BodyLayout
  include Cms::Model::Layout
  include Cms::Addon::BodyLayoutHtml
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  store_in collection: "cms_body_layouts"
  set_permission_name "cms_layouts"

  field :parts, type: SS::Extensions::Words, default: ""

  index({ site_id: 1, filename: 1 }, { unique: true })

  before_save :seq_filename, if: ->{ basename.blank? }

  permit_params :parts

  private
    def validate_filename
      self.filename = "/"
    end

    def set_depth
      self.depth = 1
    end

    def seq_filename
      self.filename = "#{id}.layout.html"
    end
end
