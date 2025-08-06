module Cms::Addon
  module LayoutHtml
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      belongs_to :loop_setting, class_name: 'Cms::LoopSetting'
      permit_params :html, :loop_setting_id

      before_save :set_html
    end

    def set_html
      if loop_setting_id.present?
        self.html = loop_setting.custom_html
      end
    end
  end
end
