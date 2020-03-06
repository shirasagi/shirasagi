module Gws::Addon::Notice::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :notice_new_days, type: Integer

    permit_params :notice_new_days
  end

  def notice_new_days
    self[:notice_new_days].presence || 7
  end
end
