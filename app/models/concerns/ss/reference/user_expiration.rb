module SS::Reference::UserExpiration
  extend ActiveSupport::Concern

  included do
    scope :state, ->(state) {
      return active if state.blank? || state == 'enabled'
      return expired if state == 'disabled'
      return where({})
    }
    scope :active, ->(date = Time.zone.now) {
      where('$and' => [
        { '$or' => [{ account_start_date: nil }, { :account_start_date.lte => date }] },
        { '$or' => [{ account_expiration_date: nil }, { :account_expiration_date.gt => date }] }
      ])
    }
    scope :expired, ->(date = Time.zone.now) {
      where('$or' => [
        { :account_start_date.exists => true , :account_start_date.gt => date },
        { :account_expiration_date.exists => true , :account_expiration_date.lt => date }
      ])
    }
  end

  def active?
    now = Time.zone.now
    return false if account_start_date.present? && account_start_date >= now
    return false if account_expiration_date.present? && account_expiration_date < now
    true
  end

  def active_state
    active? ? :active : :expired
  end

  def active_state_name
    I18n.t "views.options.state.#{active_state}"
  end

  def search_state_options
    %w(enabled disabled all).map { |m| [ I18n.t("views.options.state.#{m}"), m ] }
  end

  def disable
    now = Time.zone.now
    update_attributes(account_expiration_date: now) if account_expiration_date.blank? || account_expiration_date > now
  end
end

