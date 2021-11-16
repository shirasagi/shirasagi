module SS::Locatable
  extend ActiveSupport::Concern

  included do
    if Rails.env.test?
      define_method(:url) { SS.config.ss.file_url_with == "name" ? url_with_name : url_with_filename }
      define_method(:full_url) { SS.config.ss.file_url_with == "name" ? full_url_with_name : full_url_with_filename }
    elsif SS.config.ss.file_url_with == "name"
      define_method(:url) { url_with_name }
      define_method(:full_url) { full_url_with_name }
    else
      define_method(:url) { url_with_filename }
      define_method(:full_url) { full_url_with_filename }
    end
  end

  def physical_name
    id.to_s
  end

  def path
    "#{self.class.root}/ss_files/" + id.to_s.chars.join("/") + "/_/#{physical_name}"
  end

  def public_dir
    return if site.blank? || !site.respond_to?(:root_path)
    "#{site.root_path}/fs/" + id.to_s.chars.join("/") + "/_"
  end

  def public_path
    public_dir.try { |dir| "#{dir}/#{filename}" }
  end

  def url_with_filename
    "/fs/" + id.to_s.chars.join("/") + "/_/#{filename}"
  end

  def url_with_name
    if SS::FilenameUtils.url_safe_japanese?(name)
      "/fs/" + id.to_s.chars.join("/") + "/_/#{Addressable::URI.encode_component(name)}"
    else
      url_with_filename
    end
  end

  def full_url_with_filename
    return if site.blank? || !site.respond_to?(:full_root_url)
    "#{site.full_root_url}fs/" + id.to_s.chars.join("/") + "/_/#{filename}"
  end

  def full_url_with_name
    return if site.blank? || !site.respond_to?(:full_root_url)
    if SS::FilenameUtils.url_safe_japanese?(name)
      "#{site.full_root_url}fs/" + id.to_s.chars.join("/") + "/_/#{Addressable::URI.encode_component(name)}"
    else
      full_url_with_filename
    end
  end
end
