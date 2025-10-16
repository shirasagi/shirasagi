module Cms::Addon::Column::Layout
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :layout, type: String
    field :loop_setting_id, type: String
    belongs_to :loop_setting, class_name: 'Cms::LoopSetting'
    permit_params :layout, :loop_setting_id
    validates :layout, liquid_format: true
  end
end
