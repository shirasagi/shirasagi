module Cms::Addon
  module Line::Service::Hook
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      has_many :hooks, class_name: "Cms::Line::Service::Hook::Base", inverse_of: :group, dependent: :destroy
    end
  end
end
