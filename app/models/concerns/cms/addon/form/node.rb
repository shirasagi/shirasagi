module Cms::Addon::Form::Node
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :st_forms, class_name: 'Cms::Form'
    permit_params st_form_ids: []
  end
end
