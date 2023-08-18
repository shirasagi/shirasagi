module SS::ReadableFile
  extend ActiveSupport::Concern

  def read
    Fs.exist?(path) ? Fs.binread(path) : nil
  end

  def to_io(&block)
    Fs.exist?(path) ? Fs.to_io(path, &block) : nil
  end
end
