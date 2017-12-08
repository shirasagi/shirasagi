module Gws::Memo::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :memo_filesize_limit, type: Integer
    field :memo_reminder, type: Integer, default: 3
    field :memo_email, type: String

    permit_params :memo_filesize_limit, :memo_reminder, :memo_email

    validates :memo_reminder, numericality: true
    validates :memo_email, email: true, if: ->{ memo_email.present? }
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

  def memo_email
    self[:memo_email]
  end

  class << self
    def allowed?(action, user, opts = {})
      Gws::Memo::Signature.allowed?(action, user, opts)
    end
  end

end
