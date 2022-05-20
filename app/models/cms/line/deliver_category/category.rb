class Cms::Line::DeliverCategory::Category < Cms::Line::DeliverCategory::Base
  include Category::Addon::Setting

  seqid :id

  class << self
    def page_condition
      st_category_ids = criteria.pluck(:st_category_ids).flatten
      { category_ids: { '$in' => st_category_ids } }
    end
  end
end
