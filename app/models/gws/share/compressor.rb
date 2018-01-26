class Gws::Share::Compressor
  attr_accessor :user, :items, :filename, :name
  attr_accessor :root, :path, :url

  def initialize(user, attr = {})
    self.user     = user
    self.items    = attr[:items]
    self.items    = Gws::Share::File.in(id: items) if items.is_a?(Array)
    self.filename = attr[:filename] || "share_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    self.name     = attr[:name]

    file = SS::DownloadJobFile.new(user, filename)
    self.root = file.class.root
    self.path = file.path
    self.url  = attr[:url] || file.url(name: name)
  end

  def serialize
    { items: items.map(&:id), filename: filename, name: name, url: url }
  end

  def type
    'application/zip'
  end

  def deley_download?
    sizes = items.map(&:size)
    return true if sizes.inject(:+) >= SS.config.env.deley_download['min_filesize'].to_i
    return true if sizes.size >= SS.config.env.deley_download['min_count'].to_i
    false
  end

  def delay_message
    I18n.t('gws.notice.delay_download_with_message')
  end

  def save
    ::FileUtils.mkdir_p(::File.dirname(path))
    ::File.delete(path) if ::File.exist?(path)

    filenames = []

    Zip::File.open(path, Zip::File::CREATE) do |zip|
      items.each do |item|
        filename = item.download_filename
        filename = filename.sub(/(\.[^.]+)$/, ".#{item.id}" + '\\1') if filenames.include?(filename)
        filenames << filename
        zip.add(NKF::nkf('-sx --cp932', filename), item.path) if ::File.exist?(item.path)
      end
    end

    ::File.exist?(path)
  end
end
