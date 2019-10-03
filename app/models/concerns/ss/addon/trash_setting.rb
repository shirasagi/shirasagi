module SS::Addon
  module TrashSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :trash_threshold, type: String, default: 14
      permit_params :trash_threshold
    end
  end
end
