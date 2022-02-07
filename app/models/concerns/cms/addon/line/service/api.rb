module Cms::Addon
  module Line::Service::Api
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :api_url, type: String
      field :api_log_filename, type: String
      validates :api_url, presence: true
      validates :api_log_filename, presence: true
      permit_params :api_url, :api_log_filename
    end
  end
end
