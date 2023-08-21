module Member::Addon::Photo
  module Slide
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :node_url, type: String
      permit_params :node_url
    end
  end
end
