module Gws::Notice::Notification
  extend ActiveSupport::Concern

  included do
    field :notification_noticed, type: DateTime
    permit_params :notification_noticed
  end
end
