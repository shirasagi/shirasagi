module Cms::Addon::Column::Layout
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :layout, type: String
    field :loop_setting_id, type: String
    belongs_to :loop_setting, class_name: 'Cms::LoopSetting'
    permit_params :layout, :loop_setting_id
    validates :layout, liquid_format: true
    before_save :set_html

    def set_html
      if loop_setting_id.present?
        self.layout = loop_setting.html
      end
    end
  end
end
