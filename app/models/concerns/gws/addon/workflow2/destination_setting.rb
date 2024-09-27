module Gws::Addon::Workflow2::DestinationSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Workflow2::DestinationSetting

  included do
    permit_params destination_group_ids: [], destination_user_ids: []
  end
end
