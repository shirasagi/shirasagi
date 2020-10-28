module Opendata::Addon::CmsRef::AttachmentFile
  extend SS::Addon
  extend ActiveSupport::Concern
  include Opendata::CmsRef::Page

  included do
    field :assoc_filename, type: String
    field :assoc_method, type: String, default: 'auto'

    validates :assoc_method, inclusion: { in: %w(none auto) }

    scope :and_associated_file, ->(file) do
      where({ '$or' => [assoc_file_id: file.id, assoc_filename: file.filename] })
    end
  end

  def associate_resource_with_file!(page, file, license_id, text)
    file.uploaded_file do |tmp_file|
      self.name = file.name.gsub(/\..*$/, '')
      self.license_id = license_id
      self.text = text
      self.in_file = tmp_file
      self.assoc_site_id = page.site.id
      self.assoc_node_id = page.parent.id
      self.assoc_page_id = page.id
      self.assoc_filename = file.filename
      self.assoc_file_id = file.id
      self.save!
    end
  end

  def update_resource_with_file!(page, file, license_id, text)
    self.name = file.name.gsub(/\..*$/, '')
    self.license_id = license_id
    self.text = text
    self.assoc_site_id = page.site.id
    self.assoc_node_id = page.parent.id
    self.assoc_page_id = page.id
    self.assoc_filename = file.filename
    self.assoc_file_id = file.id
    self.updated = Time.zone.now
    self.save!

    resource_file = self.file

    ::Fs.binwrite(resource_file.path, ::Fs.binread(file.path))
    resource_file.name = file.name
    resource_file.filename = file.filename
    resource_file.size = file.size
    resource_file.content_type = file.content_type
    resource_file.updated = Time.zone.now
    resource_file.save!
  end

  def assoc_file
    if assoc_page.present? && (assoc_file_id.present? || assoc_filename.present?)
      assoc_page.attached_files.find { |file| (file.id == assoc_file_id || file.filename == assoc_filename) }
    end
  end

  def assoc_method_options
    %w(none auto).map do |v|
      [ I18n.t("opendata.crawl_update_name.#{v}"), v ]
    end
  end
end
