class SS::DownloadJobFile
  include ActiveModel::Model

  attr_reader :user, :filename, :path
  attr_accessor :in_file, :in_path

  def url
    Rails.application.routes.url_helpers.
      sns_download_job_files_path(user: user.id, filename: filename)
  end

  def read
    ::File.exists?(path) ? ::File.read(path) : nil
  end

  def content_type
    ::SS::MimeType.find(path, nil)
  end

  def save
    if in_file
      original_file_path = in_file.path
    elsif in_path
      original_file_path = in_path
    else
      return false
    end

    ::FileUtils.mkdir_p(::File.dirname(path))
    ::File.write(path, ::File.read(original_file_path))
    return true
  end

  def initialize(user, filename)
    @user = user
    @filename = filename

    id_path = sprintf("%02d", user.id.to_s.slice(0, 2)) + "/#{user.id}"
    @path = "#{Rails.root}/private/download/#{id_path}/#{filename}"
  end

  class << self
    def find(user, filename)
      item = self.new(user, filename)
      ::File.exist?(item.path) ? item : nil
    end
  end
end
