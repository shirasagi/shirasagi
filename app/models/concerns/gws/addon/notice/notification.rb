module Gws::Addon::Notice::Notification
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :notification_noticed, type: DateTime
    permit_params :notification_noticed
  end
end
