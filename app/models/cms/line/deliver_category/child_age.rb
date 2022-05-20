class Cms::Line::DeliverCategory::ChildAge < Cms::Line::DeliverCategory::Base
  include Cms::Addon::Line::DeliverCategory::ChildAge
  include Cms::Addon::Line::DeliverCategory::Pickup

  seqid :id

  embeds_ids :st_pages, class_name: "Cms::Page"
  permit_params st_page_ids: []

  validate :validate_condition_body, if: ->{ parent }

  class << self
    def page_condition
      st_category_ids = criteria.pluck(:st_category_ids).flatten
      { category_ids: { '$in' => st_category_ids } }
    end
  end
end
