class Cms::Line::DeliverCategory::Category < Cms::Line::DeliverCategory::Base
  include Cms::Addon::Line::DeliverCategory::Category
  include Cms::Addon::Line::DeliverCategory::Condition

  seqid :id

  def type
    "category"
  end
end
