module SS::Zip
  METHOD_STORED = 0
  VERSION_NEEDED_TO_EXTRACT_UNICODE_NAMES = 63

  class Writer
    private_class_method :new

    class << self
      def create(path, comment: nil)
        instance = new(path, comment: comment)
        yield instance
      ensure
        instance.close
      end
    end

    def initialize(path, comment: nil)
      @now = Time.zone.now
      @main_file = ::File.open(path, "wb")
      @comment = comment

      dir = ::File.dirname(path)
      basename = ::File.basename(path)
      central_path = "#{dir}/.#{basename}.cdir"
      @cdir_file = ::File.open(central_path, "wb")

      @entry_count = 0
    end

    def add_file(name, &block)
      raise "now writing" if @writing
      @writing = true

      offset = @main_file.tell

      writer = SS::Zip::FileData.new(file: @main_file, name: name)
      header = SS::Zip::Header.new(
        name: name, last_modified: @now, crc32: 0,
        compressed_size: 0, uncompressed_size: 0, offset: offset)
      @main_file.write(header.pack_for_local)

      yield writer
      writer.commit

      header.crc32 = writer.crc32
      header.compressed_size = writer.size
      header.uncompressed_size = writer.size
      @main_file.seek(offset, ::IO::SEEK_SET)
      @main_file.write(header.pack_for_local)
      @main_file.seek(0, ::IO::SEEK_END)
      @main_file.flush

      @cdir_file.write header.pack_for_central
      @cdir_file.flush

      @entry_count += 1
    ensure
      @writing = false
    end

    def close
      cdir_offset = @main_file.tell
      @cdir_file.close
      ::IO.copy_stream(@cdir_file.path, @main_file)
      eocd_offset = @main_file.tell
      cdir_size = eocd_offset - cdir_offset
      # zip64 end of central directory record
      SS::Zip.write_64_e_o_c_d(@main_file, cdir_offset, cdir_size, @entry_count)
      # zip64 end of central directory locator
      SS::Zip.write_64_eocd_locator(@main_file, eocd_offset)
      # end of central directory record
      SS::Zip.write_e_o_c_d(@main_file, cdir_offset, cdir_size, @entry_count, @comment)

      @main_file.close rescue nil
      @main_file = nil

      ::File.unlink(@cdir_file.path)
    end
  end

  class Header
    include ActiveModel::Model

    attr_reader :name
    attr_accessor :last_modified, :crc32, :compressed_size, :uncompressed_size, :offset

    def initialize(name:, **options)
      @name = name
      @last_modified = Time.zone.now
      @crc32 = nil
      @compressed_size = 0
      @uncompressed_size = 0
      super(**options)
    end

    def pack_for_local
      if compressed_size > 0xFFFFFFFF || uncompressed_size > 0xFFFFFFFF
        # NOTE: This entry in the Local header MUST include BOTH original and compressed file size fields.
        zip64_extra_block = [
          0x0001, # Zip64 extended information extra field
          16, # Size of Zip64 extra block
          compressed_size, # Original uncompressed file size
          uncompressed_size # Size of compressed data
        ].pack('vvQ<Q<')
      else
        # Zip64 placeholder
        zip64_extra_block = [ 0x9999, 0, 0, 0 ].pack('vvQ<Q<')
      end

      [
        ::Zip::LOCAL_ENTRY_SIGNATURE, # local file header signature
        ::Zip::VERSION_NEEDED_TO_EXTRACT_ZIP64, # version needed to extract
        ::Zip::Entry::EFS, # general purpose bit flag
        METHOD_STORED, # compression method
        SS::Zip.to_binary_dos_time(last_modified), # last mod file time
        SS::Zip.to_binary_dos_date(last_modified), # last mod file date
        crc32 || 0,
        compressed_size > 0xFFFFFFFF ? 0xFFFFFFFF : compressed_size,
        uncompressed_size > 0xFFFFFFFF ? 0xFFFFFFFF : uncompressed_size,
        name.bytesize, # file name length
        zip64_extra_block.bytesize, # Zip64 extend block size
        name
      ].pack('VvvvvvVVVvva*') + zip64_extra_block
    end

    def pack_for_central
      zip64_info = ''.force_encoding(::Encoding::ASCII_8BIT)

      # central directory header には local file header のような制約はない。
      # 32bit で収まらない場合にのみ、ZIP64に設定する。
      if compressed_size > 0xFFFFFFFF
        zip64_info += [ compressed_size ].pack('Q<')
      end
      if uncompressed_size > 0xFFFFFFFF
        zip64_info += [ uncompressed_size ].pack('Q<')
      end
      if offset > 0xFFFFFFFF
        zip64_info += [ offset ].pack('Q<')
      end
      if zip64_info.present?
        zip64_extra_block = [ 0x0001, zip64_info.bytesize ].pack('vv') + zip64_info
      else
        # 全てが32bitで収まる場合は ZIP64 拡張は必要ない。
        zip64_extra_block = ''
      end

      [
        ::Zip::CENTRAL_DIRECTORY_ENTRY_SIGNATURE, # central file header signature
        VERSION_NEEDED_TO_EXTRACT_UNICODE_NAMES, # lower byte of version made-by which indicates the ZIP specification version
        ::Zip::FSTYPE_UNIX, # upper byte of version made-by which indicates the compatibility of the file attribute information.
        ::Zip::VERSION_NEEDED_TO_EXTRACT_ZIP64, # version needed to extract
        ::Zip::Entry::EFS, # general purpose bit flag
        METHOD_STORED, # compression method
        SS::Zip.to_binary_dos_time(last_modified), # last mod file time
        SS::Zip.to_binary_dos_date(last_modified), # last mod file date
        crc32 || 0,
        compressed_size > 0xFFFFFFFF ? 0xFFFFFFFF : compressed_size, # compressed size
        uncompressed_size > 0xFFFFFFFF ? 0xFFFFFFFF : uncompressed_size, # uncompressed size
        name.bytesize, # file name length
        zip64_extra_block.bytesize, # extra field length
        0, # file comment length
        0, # disk number start
        1, # internal file attributes
        (::Zip::FILE_TYPE_FILE << 12 | (0o644 & 0o7777)) << 16, # external file attributes
        offset > 0xFFFFFFFF ? 0xFFFFFFFF : offset, # relative offset of local header
        name, # file name (variable size)
      ].pack('VCCvvvvvVVVvvvvvVVa*') + zip64_extra_block
    end
  end

  class FileData
    include ActiveModel::Model

    attr_accessor :file, :name
    attr_reader :size, :crc32

    def initialize(*args, **options)
      super

      @size = 0
      @crc32 = 0
    end

    def write(str)
      @crc32 = ::Zlib.crc32(str, @crc32)
      file.write(str)
      @size += str.bytesize
    end

    def commit
    end
  end

  module_function

  # Register CX, the Time:
  # Bits 0-4  2 second increments (0-29)
  # Bits 5-10 minutes (0-59)
  # bits 11-15 hours (0-24)
  def to_binary_dos_time(time)
    (time.sec / 2) + (time.min << 5) + (time.hour << 11)
  end

  # Register DX, the Date:
  # Bits 0-4 day (1-31)
  # bits 5-8 month (1-12)
  # bits 9-15 year (four digit year minus 1980)
  def to_binary_dos_date(time)
    time.day + (time.month << 5) + ((time.year - 1980) << 9)
  end

  # zip64 end of central directory record
  def write_64_e_o_c_d(io, offset, cdir_size, entry_count) #:nodoc:
    tmp = [
      ::Zip::CentralDirectory::ZIP64_END_OF_CDS, # zip64 end of central dir signature
      44, # size of zip64 end of central directory record (excludes signature and field itself)
      ::Zip::VERSION_MADE_BY, #  version made by
      ::Zip::VERSION_NEEDED_TO_EXTRACT_ZIP64, # version needed to extract
      0, # number of this disk
      0, # number of the disk with the start of the central directory
      entry_count, # total number of entries in the central directory on this disk
      entry_count, # total number of entries in the central directory
      cdir_size, # size of the central directory
      offset # offset of start of central directory with respect to the starting disk number
    ]
    io << tmp.pack('VQ<vvVVQ<Q<Q<Q<')
  end

  # zip64 end of central directory locator
  def write_64_eocd_locator(io, zip64_eocd_offset)
    tmp = [
      ::Zip::CentralDirectory::ZIP64_EOCD_LOCATOR,
      0, # number of disk containing the start of zip64 eocd record
      zip64_eocd_offset, # offset of the start of zip64 eocd record in its disk
      1 # total number of disks
    ]
    io << tmp.pack('VVQ<V')
  end

  # end of central directory record
  def write_e_o_c_d(io, offset, cdir_size, entry_count, comment) #:nodoc:
    tmp = [
      ::Zip::CentralDirectory::END_OF_CDS,
      0, # number of this disk
      0, # number of the disk with the start of the central directory
      [entry_count, 0xFFFF].min, # total number of entries in the central directory on this disk
      [entry_count, 0xFFFF].min, # total number of entries in the central directory
      [cdir_size, 0xFFFFFFFF].min, # size of the central directory
      [offset, 0xFFFFFFFF].min, # offset of start of central directory with respect to the starting disk number
      comment ? comment.bytesize : 0 # comment size
    ]
    io << tmp.pack('VvvvvVVv')
    if comment
      io << comment
    end
  end
end
