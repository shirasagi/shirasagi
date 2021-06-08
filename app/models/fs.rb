module Fs
  if SS.config.env.storage == "grid_fs"
    include ::Fs::GridFs
  else
    include ::Fs::File
  end

  module_function

  def same_data?(path, data)
    return false unless Fs.exists?(path)
    return false if Fs.size(path) != data.length

    begin
      io = Fs.to_io(path)
      ::FileUtils.compare_stream(io, StringIO.new(data))
    ensure
      io.close rescue nil
    end
  end

  def write_data_if_modified(path, data)
    return if Fs.same_data?(path, data)
    Fs.binwrite(path, data)
  end
end
