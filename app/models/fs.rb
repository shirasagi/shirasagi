module Fs
  MAX_COMPARE_FILE_SIZE = SS.config.env.max_compare_file_size || 100 * 1_024
  DEFAULT_BUFFER_SIZE = 4 * 1_024
  DEFAULT_HEAD_LOGS = SS.config.job.head_logs || 1_000
  DEFAULT_TAIL_BYTES = 16 * 1_024
  SAFE_IMAGE_SUB_TYPES = %w(gif jpeg png webp).freeze

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
    return false unless Fs.exist?(path)
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

  def head_lines(path, limit: nil)
    return [] if !path || !Fs.exist?(path)

    limit ||= DEFAULT_HEAD_LOGS
    texts = []
    Fs.to_io(path) do |f|
      limit.times do
        line = f.gets || break
        line.force_encoding(Encoding.default_internal)
        line.chomp!
        texts << line
      end
    end
    texts
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    []
  end

  def sanitize_filename(filename)
    filename.gsub(/[<>:"\/\\|?*]/, '_').slice(0..60)
  end

  def tail_lines(path, limit_in_bytes: nil)
    limit_in_bytes ||= DEFAULT_TAIL_BYTES
    limit_in_bytes = DEFAULT_TAIL_BYTES if limit_in_bytes < 256

    Fs.to_io(path) do |f|
      size = f.size
      if size <= limit_in_bytes
        ret = f.read
        next "" if ret.blank?

        ret.force_encoding(Encoding::UTF_8)
        next ret
      end

      f.seek(- limit_in_bytes, ::IO::SEEK_END)
      ret = f.read(limit_in_bytes)
      next "" if ret.blank?

      # UTF-8 として不正な位置から読み出している可能性がある。
      # 以下のループで、UTF-8 として正しい位置を求める。
      succeeded = false
      6.times do |tail_pos|
        6.times do |head_pos|
          tmp = ret[head_pos..-(tail_pos + 1)]
          tmp.force_encoding(Encoding::UTF_8)

          byte_count = 0
          tmp.each_codepoint { |cp| byte_count += cp.chr(Encoding::UTF_8).bytes.length }

          ret = tmp
          succeeded = true
          break
        rescue => e
          Rails.logger.debug { "#{e.class} (#{e.message})" }
          next
        end

        break if succeeded
      end
      # UTF-8 として正しい位置を求められなかった
      return "" unless succeeded

      # 先頭行は中途半端な行の可能性が高いので削除する
      lf_pos = ret.index("\n")
      ret = ret[lf_pos + 1..-1] if lf_pos

      ret
    end
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    ""
  end

  def zip_safe_name(name)
    return name if name.blank?

    if Zip.unicode_names
      SS::FilenameUtils.convert_to_url_safe_japanese(name)
    else
      name.encode('cp932', invalid: :replace, undef: :replace, replace: "_")
    end
  end

  def zip_safe_path(name)
    return name if name.blank?
    name.split("/").map { |part| Fs.zip_safe_name(part) }.join("/")
  end

  def safe_create(path, binary: false, &block)
    path = ::File.expand_path(path, Rails.root)

    basename = ::File.basename(path)
    dirname = ::File.dirname(path)
    ::FileUtils.mkdir_p(dirname) unless ::Dir.exist?(dirname)

    tmp_path = "#{dirname}/.#{basename}.tmp"
    options = binary ? "wb" : "w"
    ::File.open(tmp_path, options, &block)

    ::FileUtils.mv(tmp_path, path, force: true)
  ensure
    if tmp_path
      ::FileUtils.rm_f(tmp_path) rescue nil
    end
  end
end
