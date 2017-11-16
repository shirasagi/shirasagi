class Webmail::StoredMailPart
  attr_accessor :section
  attr_accessor :part

  def initialize(part, section = nil)
    self.section = section
    self.part = part
  end

  def content_type
    part.content_type.downcase
  end

  def attachment?
    part.attachment?
  end

  def image?
    part.main_type.casecmp('IMAGE')
  end

  def link_target
    image? ? '_blank' : nil
  end

  def filename
    part.filename
  end

  def read
    part.read
  end

  def decoded
    part.decoded
  end
end
