class Cms::EditorTemplate
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Cms::Addon::Html
  include Cms::Addon::Thumb
  include Fs::FilePreviewable

  set_permission_name "cms_editor_templates", :edit

  seqid :id
  field :name, type: String
  field :description, type: String
  field :order, type: Integer
  permit_params :name, :description, :order
  validates :name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 400 }

  default_scope -> { order_by(order: 1, name: 1) }

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end

    def ckeditor?
      SS.config.cms.html_editor == "ckeditor"
    end

    def tinymce?
      SS.config.cms.html_editor == "tinymce"
    end
  end

  def export_for_ckeditor
    {
      title: name,
      image: thumb_path,
      description: description,
      html: html
    }.to_json
  end

  def thumb_path
    url = thumb.present? ? thumb.url : SS.config.cms.editor_template_thumb

    # trim leading slash because it is required relative path from root.
    url = url[1..-1] if url.start_with?("/")
    url
  end

  def file_previewable?(file, site:, user:, member:)
    return false if thumb_id != file.id
    return false if user.blank?

    true
  end
end
