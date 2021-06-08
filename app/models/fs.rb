module Fs
  MAX_COMPARE_FILE_SIZE = SS.config.env.max_compare_file_size || 100 * 1_024
  DEFAULT_BUFFER_SIZE = 4 * 1_024

  if SS.config.env.storage == "grid_fs"
    include ::Fs::GridFs
  else
    include ::Fs::File
  end

  module_function

  if RUBY_VERSION > "2.4"
    def new_buffer(buff_size)
      String.new(capacity: buff_size)
    end
  else
    def new_buffer(_buff_size)
      # String.new
      ''
    end
  end

  def compare_stream_head(lhs, rhs, max_size: nil)
    max_size ||= Fs::MAX_COMPARE_FILE_SIZE
    lhs_buff = Fs.new_buffer(Fs::DEFAULT_BUFFER_SIZE)
    rhs_buff = Fs.new_buffer(Fs::DEFAULT_BUFFER_SIZE)

    nread = 0
    loop do
      return true if nread >= max_size

      lhs.read(Fs::DEFAULT_BUFFER_SIZE, lhs_buff)
      rhs.read(Fs::DEFAULT_BUFFER_SIZE, rhs_buff)
      nread += lhs_buff.length

      return true if lhs_buff.empty? && rhs_buff.empty?
      break if lhs_buff != rhs_buff
    end

    false
  end

  def compare_file_head(src, dest, max_size: nil)
    # Fs.cmp(src, dest)
    src_io = Fs.to_io(src)
    dest_io = Fs.to_io(dest)

    Fs.compare_stream_head(src_io, dest_io, max_size: max_size)
  ensure
    dest_io.close if dest_io
    src_io.close if src_io
  end

  def same_data?(path, data)
    return false unless Fs.exists?(path)
    return false if Fs.size(path) != data.length

    begin
      io = Fs.to_io(path)
      Fs.compare_stream_head(io, StringIO.new(data))
    ensure
      io.close rescue nil
    end
  end

  def write_data_if_modified(path, data)
    return if Fs.same_data?(path, data)
    Fs.binwrite(path, data)
  end
end
