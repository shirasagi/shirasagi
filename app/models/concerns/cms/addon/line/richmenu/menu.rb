module Cms::Addon
  module Line::Richmenu::Menu
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      has_many :menus, class_name: "Cms::Line::Richmenu::Menu", inverse_of: :group, dependent: :destroy
    end
  end
end
