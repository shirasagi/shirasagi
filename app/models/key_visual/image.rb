class KeyVisual::Image
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include SS::Relation::File
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Cms::Lgwan::Page

  set_permission_name "key_visual_images"

  field :link_url, type: String
  field :remark_html, type: String
  field :display_remarks, type: Array, default: []

  belongs_to_file :file

  validates :file_id, presence: true
  validates :display_remarks, inclusion: { in: I18n.t("key_visual.options.display_remarks").keys.map(&:to_s) },
    if: -> { display_remarks.present? }

  permit_params :link_url, :remark_html
  permit_params display_remarks: []

  after_generate_file :generate_relation_public_file, if: ->{ public? }
  after_remove_file :remove_relation_public_file

  default_scope ->{ where(route: "key_visual/image") }

  def display_title?
    display_remarks.include?("title")
  end

  def display_remark_html?
    display_remarks.include?("remark_html")
  end

  def display_remarks_label
    I18n.t("key_visual.options.display_remarks").map do |k, v|
      display_remarks.include?(k.to_s) ? v : nil
    end.compact.join(", ")
  end
end
