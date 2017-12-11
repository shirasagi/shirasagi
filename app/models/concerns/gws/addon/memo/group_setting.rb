module Gws::Addon::Memo::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :memo_filesize_limit, type: Integer
    field :memo_reminder, type: Integer, default: 3

    permit_params :memo_filesize_limit, :memo_reminder

    validates :memo_reminder, numericality: true
  end

  def memo_filesize_limit
    self[:memo_filesize_limit]
  end

  def memo_reminder
    self[:memo_reminder]
  end

  def memo_reminder_options
    I18n.t('gws/memo/group_setting.options.reminder').
      map.with_index.to_a
  end

  def memo_reminder_name
    I18n.t('gws/memo/group_setting.options.reminder')[memo_reminder]
  end
end
