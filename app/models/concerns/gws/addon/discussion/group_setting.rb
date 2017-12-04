module Gws::Addon::Discussion::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :discussion_new_days, type: Integer
    field :discussion_unseen_interval, type: Integer

    permit_params :discussion_new_days, :discussion_unseen_interval
  end

  def discussion_new_days
    self[:discussion_new_days].presence || 7
  end

  def discussion_unseen_interval_options
    [
      [I18n.t("gws/discussion.options.discussion_unseen_interval.none"),  nil],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.5min"), 300000],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.1min"), 60000],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.30sec"), 30000],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.10sec"), 10000]
    ]
  end

  #class << self
  #  # Permission for navigation view
  #  def allowed?(action, user, opts = {})
  #    return true if Gws::Board::Category.allowed?(action, user, opts)
  #    super
  #  end
  #end
end
