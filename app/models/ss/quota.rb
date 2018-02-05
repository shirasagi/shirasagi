class SS::Quota
  include ActiveSupport::NumberHelper

  attr_accessor :quota_bytes, :usage_bytes

  def initialize(attr = {})
    self.quota_bytes = attr[:quota_bytes]
    self.usage_bytes = attr[:usage_bytes]
  end

  def over?(diff = 0)
    return false if quota_bytes <= 0
    usage_bytes + diff >= quota_bytes
  end

  def label
    usage = over? ? quota_bytes : usage_bytes
    "#{number_to_human_size(usage)}/#{number_to_human_size(quota_bytes)}"
  end

  def percentage
    return 0 if quota_bytes <= 0
    percentage = (usage_bytes.to_f / quota_bytes.to_f) * 100
    percentage > 100 ? 100 : percentage
  end
end
