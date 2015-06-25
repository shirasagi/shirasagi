module Ezine::Addon
  module DeliverPlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :deliver_date, type: DateTime
      permit_params :deliver_date
    end
  end
end
