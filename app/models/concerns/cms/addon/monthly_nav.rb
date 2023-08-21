module Cms::Addon
  module MonthlyNav
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :periods, type: Integer
      permit_params :periods

      validates :periods, presence: true
    end
  end
end
