class Webmail::StoredMailPart
  attr_accessor :section
  attr_accessor :part

  delegate :attachment?, :filename, :read, :decoded, to: :part

  def initialize(part, section = nil)
    self.section = section
    self.part = part
  end

  def content_type
    part.content_type.downcase
  end

  def image?
    part.main_type.upcase == 'IMAGE'
  end

  def link_target
    image? ? '_blank' : nil
  end
end
