class KeyVisual::Image
  include Cms::Model::Page
  include SS::Relation::File
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "key_visual_images"

  field :link_url, type: String

  belongs_to_file :file

  validates :in_file, presence: true, if: -> { file_id.blank? }

  before_save :seq_filename, if: ->{ basename.blank? }

  permit_params :link_url

  default_scope ->{ where(route: "key_visual/image") }

  public
    def serve_static_file?
      false
    end

  private
    def validate_filename
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
