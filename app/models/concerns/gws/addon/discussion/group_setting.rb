module Gws::Addon::Discussion::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :discussion_quota, type: Integer, default: nil
    field :discussion_filesize_limit, type: Integer, default: nil
    field :discussion_new_days, type: Integer
    field :discussion_unseen_interval, type: Integer
    field :discussion_recent_limit, type: Integer, default: 5
    field :discussion_todo_limit, type: Integer, default: 5
    field :discussion_comment_limit, type: Integer, default: 1000

    permit_params :discussion_quota, :discussion_filesize_limit,
      :discussion_new_days, :discussion_unseen_interval, :discussion_recent_limit,
      :discussion_todo_limit, :discussion_comment_limit
  end

  def discussion_new_days
    self[:discussion_new_days].presence || 7
  end

  def discussion_unseen_interval_options
    [
      [I18n.t("gws/discussion.options.discussion_unseen_interval.none"), nil],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.5min"), 300_000],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.1min"), 60_000],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.30sec"), 30_000],
      [I18n.t("gws/discussion.options.discussion_unseen_interval.10sec"), 10_000]
    ]
  end
end
