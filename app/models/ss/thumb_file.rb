class SS::ThumbFile
  include SS::Model::File

  default_scope ->{ where(model: "ss/thumb_file") }

  index({ original_id: 1 })

  belongs_to :original, foreign_key: "original_id", class_name: 'SS::File'
  field :image_size, type: SS::Extensions::Sizes
  field :image_size_name, type: String

  validates :original_id, presence: true
  validates :image_size, presence: true
  validates :image_size_name, presence: true

  def public_dir
    return if site.blank? || !site.respond_to?(:root_path)
    "#{site.root_path}/fs/" + original_id.to_s.split(//).join("/") + "/_/thumb"
  end

  def url_with_filename
    "/fs/" + original_id.to_s.split(//).join("/") + "/_/thumb/#{original.filename}"
  end

  def url_with_name
    url_with_filename
  end

  def full_url_with_filename
    return if site.blank? || !site.respond_to?(:full_root_url)
    "#{site.full_root_url}fs/" + original_id.to_s.split(//).join("/") + "/_/thumb/#{original.filename}"
  end

  def full_url_with_name
    full_url_with_filename
  end

  def thumb_url
    url_with_filename
  end

  def remove_file
    Fs.rm_rf(path)
    remove_public_file
  end
end
