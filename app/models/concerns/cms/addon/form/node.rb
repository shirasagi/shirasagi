module Cms::Addon::Form::Node
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :st_forms, class_name: 'Cms::Form'
    belongs_to :st_form_default, class_name: 'Cms::Form'
    permit_params st_form_ids: []
    permit_params :st_form_default_id
  end
end
