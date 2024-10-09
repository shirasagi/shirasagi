module Gws::Addon::Workflow2::FormPurpose
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :purposes, class_name: "Gws::Workflow2::Form::Purpose"
    permit_params purpose_ids: []
  end
end
