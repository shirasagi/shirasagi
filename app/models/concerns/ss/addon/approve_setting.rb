module SS::Addon::ApproveSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :forced_update, type: String
    field :close_confirmation, type: String
    field :approve_remind_state, type: String
    field :approve_remind_later, type: String
    validates :forced_update, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :close_confirmation, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :approve_remind_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :approve_remind_later, "ss/duration" => true
    validates :approve_remind_later, presence: true, if: ->{ approve_remind_state_enabled? }
    permit_params :forced_update, :close_confirmation, :approve_remind_state, :approve_remind_later
  end

  def forced_update_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def close_confirmation_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def approve_remind_state_options
    %w(disabled enabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def approve_remind_later_options
    %w(1.day 2.days 3.days 4.days 5.days 6.days 1.week 2.weeks).map do |v|
      [ I18n.t("ss.options.approve_remind_later.#{v.sub('.', '_')}"), v ]
    end
  end

  def close_confirmation_enabled?
    close_confirmation == 'enabled' || close_confirmation.blank?
  end

  def approve_remind_state_enabled?
    approve_remind_state == 'enabled'
  end
end
