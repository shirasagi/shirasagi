class Webmail::MailPart
  attr_accessor :section
  attr_accessor :part
  attr_accessor :param
  attr_accessor :disposition
  attr_accessor :disposition_param
  attr_accessor :data

  def initialize(part, section = nil, data = nil)
    self.section = section
    self.part = part
    self.param = part.param || {}
    self.disposition = part.disposition
    self.disposition_param = disposition.try(:param) || {}
    self.data = data
  end

  def content_type
    "#{part.media_type}/#{part.subtype}".downcase
  end

  def attachment?
    disposition.present? && disposition.dsp_type == 'ATTACHMENT'
  end

  def image?
    part.media_type == 'IMAGE'
  end

  def link_target
    image? ? '_blank' : nil
  end

  def filename
    if param['NAME'].present?
      param['NAME'].toutf8
    elsif disposition_param['FILENAME'].present?
      disposition_param['FILENAME'].toutf8
    else
      "File" + section.tr('.', '-')
    end
  end

  def read
    data
  end

  def decoded
    self.class.decode(data, part)
  end

  def size
    part.size
  end

  class << self
    def list(parts)
      parts.map { |sec, part| new(part, sec) }
    end

    def decode(data, part, options = {})
      return if data.blank?

      body = ::Mail::Body.new(data)
      body.encoding = part.encoding

      data = body.decoded
      if options && options[:charset]
        charset = part.param ? part.param['CHARSET'].presence : nil
        charset = 'CP50220' if charset.try(:upcase) == 'ISO-2022-JP'

        data = data.encode('UTF-8', charset, invalid: :replace, undef: :replace) if charset
      end
      if part.subtype == 'HTML' && options && options[:html_safe]
        data = data.html_safe
      end
      data
    end
  end
end
