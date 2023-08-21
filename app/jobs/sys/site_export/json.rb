class Sys::SiteExport::Json
  extend ActiveSupport::Concern

  def initialize(path)
    @path = path
    File.write(@path, '[')
  end

  def write(data)
    if @file
      @file.write ",#{data}"
    else
      @file = File.open(@path, 'a')
      @file.write data
    end
  end

  def close
    @file.close if @file
    File.open(@path, 'a') { |f| f.write(']') }
  end
end
