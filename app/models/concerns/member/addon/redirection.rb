module Member::Addon
  module Redirection
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :redirect_url, type: String, default: "/"
      permit_params :redirect_url
    end
  end
end
