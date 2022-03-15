class SS::StreamingFile
  include SS::Model::File
  # include SS::Relation::Thumb

  attr_accessor :in_remote_url, :in_size_limit, :in_remote_basic_authentication

  before_validation :set_filename, if: ->{ in_remote_url.present? }

  validates_with SS::FileSizeValidator, if: ->{ false }

  def set_filename
    self.in_remote_url = ::Addressable::URI.escape(in_remote_url)

    basename = ::File.basename(::Addressable::URI.unencode(in_remote_url))
    self.name = basename if name.blank?
    self.filename = basename if filename.blank?
    self.content_type = ::SS::MimeType.find(filename, "application/octet-stream")
  end

  # not implemented save_file for grid-fs mode
  def save_file
    return if in_remote_url.blank?

    Fs.mkdir_p(::File.dirname(path))

    content_type = nil
    size_limit = in_size_limit.to_i

    start_fetch(in_remote_url, 10, {}) do |response|
      overall_received_bytes = 0
      content_type = response.content_type
      content_length = response.content_length.to_i

      if size_limit > 0 && content_length > 0 && content_length > size_limit
        raise SS::StreamingFile::SizeError, "file size limit exceeded"
      end

      ::File.open(path, "wb") do |f|
        response.read_body do |chunk|
          if size_limit > 0 && overall_received_bytes > size_limit
            raise SS::StreamingFile::SizeError, "file size limit exceeded"
          end

          f.write chunk
          overall_received_bytes += chunk.size
          print number_to_human_size(overall_received_bytes), " " * 10, "\r"
        end
      end
    end

    self.content_type = ::SS::MimeType.find(filename, content_type)
    self.size = Fs.stat(path).size

    # TODO: do some exif things
  end

  def start_fetch(url, limit = 10, opts = {}, &block)
    raise ArgumentError, 'HTTP redirect too deep' if limit <= 0

    uri = ::Addressable::URI.parse(url)

    ::Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|

      request = ::Net::HTTP::Get.new uri.request_uri

      if in_remote_basic_authentication.present?
        request.basic_auth in_remote_basic_authentication[0], in_remote_basic_authentication[1]
      end

      http.request request do |response|
        case response
        when Net::HTTPRedirection
          start_fetch(response['location'], limit - 1, opts, &block)
        when Net::HTTPSuccess
          yield response
        else
          raise SS::StreamingFile::ResponseError, response.code.to_s
        end
      end
    end
  end

  class SizeError < StandardError
  end

  class ResponseError < StandardError
  end
end
