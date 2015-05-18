class Cms::EditorTemplate
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission
  include Cms::Addon::Html
  include Cms::Addon::Thumb

  set_permission_name "cms_users", :edit

  seqid :id
  field :name, type: String
  field :description, type: String
  field :order, type: Integer
  permit_params :name, :description, :order
  validates :name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 400 }

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
    if thumb.present?
      # you must set relative path from root.
      "fs/#{thumb.id}/#{thumb.filename}"
    else
      # trim leading slash.
      SS.config.cms.editor_template_thumb.gsub(/^\//, '')
    end
  end
end
