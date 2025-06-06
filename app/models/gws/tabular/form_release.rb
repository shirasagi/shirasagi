class Gws::Tabular::FormRelease
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Tabular::Space
  include Gws::Reference::Tabular::Form
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission

  set_permission_name "gws_tabular_forms"

  field :revision, type: Integer, default: 0
  field :patch, type: Integer, default: 0

  validates :space, presence: true
  validates :form, presence: true
  validates :revision, presence: true, numericality: { greater_than_or_equal_to: 0, allow_blank: true },
    uniqueness: { scope: %i[site_id space_id form_id] }

  class << self
    def used_size
      size = all.total_bsonsize
      ids = all.pluck(:id)
      ids.each do |id|
        archive_path = "#{SS::File.root}/#{collection_name}/#{id.to_s.chars.join("/")}/_/archive.zip"
        size += ::File.size(archive_path) rescue 0
        migration_rb_path = "#{SS::File.root}/#{collection_name}/#{id.to_s.chars.join("/")}/_/migration.rb"
        size += ::File.size(migration_rb_path) rescue 0
      end
      size
    end
  end

  def archive_path
    return unless persisted?
    "#{SS::File.root}/#{self.class.collection_name}/#{id.to_s.chars.join("/")}/_/archive.zip"
  end

  def migration_rb_path
    return unless persisted?
    "#{SS::File.root}/#{self.class.collection_name}/#{id.to_s.chars.join("/")}/_/migration.rb"
  end
end
