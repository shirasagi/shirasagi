class Cms::CheckLinks::Source
  include ActiveModel::Model

  attr_accessor :full_url, :links, :referrers, :status
  attr_reader :sequence

  def initialize(*args, **kwargs)
    super

    @sequence = self.class.next_sequence
    @links ||= []
    @referrers ||= []
    @status ||= :to_be_examined
  end

  def self.next_sequence
    @next_sequence ||= 1
    ret = @next_sequence
    @next_sequence += 1
    ret
  end

  def self.new_from_site(site)
    full_url = Addressable::URI.parse(site.full_url)
    full_url = full_url.normalize
    new(full_url: full_url)
  end
end
