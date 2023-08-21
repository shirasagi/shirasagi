module Ezine::Addon
  module DeliverPlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :deliver_date, type: DateTime
      permit_params :deliver_date
      validates :deliver_date, datetime: true
    end
  end
end
