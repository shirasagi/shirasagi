module Opendata::Addon::CmsRef::AttachmentFile
  extend SS::Addon
  extend ActiveSupport::Concern
  include Opendata::CmsRef::Page

  included do
    field :assoc_filename, type: String
    field :assoc_method, type: String, default: 'auto'

    validates :assoc_method, inclusion: { in: %w(none auto) }

    scope :and_associated_file, ->(file) { where(assoc_filename: file.filename) }
  end

  def associate_resource_with_file!(page, file, license_id)
    file.uploaded_file do |tmp_file|
      self.name = file.name.gsub(/\..*$/, '')
      self.license_id = license_id
      self.in_file = tmp_file
      self.assoc_site_id = page.site.id
      self.assoc_node_id = page.parent.id
      self.assoc_page_id = page.id
      self.assoc_filename = file.filename
      self.save!
    end
  end

  def update_resource_with_file!(page, file, license_id)
    self.name = file.name.gsub(/\..*$/, '')
    self.license_id = license_id
    self.assoc_site_id = page.site.id
    self.assoc_node_id = page.parent.id
    self.assoc_page_id = page.id
    self.assoc_filename = file.filename
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
    if assoc_page_id.present? && assoc_filename.present?
      assoc_page.files.find_by(filename: assoc_filename) rescue nil
    end
  end

  def assoc_method_options
    %w(none auto).map do |v|
      [ I18n.t("opendata.crawl_update_name.#{v}"), v ]
    end
  end
end
