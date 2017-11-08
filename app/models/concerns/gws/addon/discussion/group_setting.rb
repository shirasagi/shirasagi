module Gws::Addon::Discussion::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :discussion_new_days, type: Integer

    permit_params :discussion_new_days
  end

  def discussion_new_days
    self[:discussion_new_days].presence || 7
  end

  #class << self
  #  # Permission for navigation view
  #  def allowed?(action, user, opts = {})
  #    return true if Gws::Board::Category.allowed?(action, user, opts)
  #    super
  #  end
  #end
end
