module Cms::Addon
  module Crumb
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :home_label, type: String
      permit_params :home_label
    end

    def home_label
      self[:home_label].presence || "HOME"
    end
  end
end
