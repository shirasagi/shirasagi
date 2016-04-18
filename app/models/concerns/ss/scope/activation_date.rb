module SS::Scope::ActivationDate
  extend ActiveSupport::Concern

  included do
    scope :state, ->(state) {
      return active if state == 'enabled'
      return expired if state == 'disabled'
      return where({})
    }
    scope :active, ->(date = Time.zone.now) {
      where('$and' => [
        { '$or' => [{ activation_date: nil }, { :activation_date.lte => date }] },
        { '$or' => [{ expiration_date: nil }, { :expiration_date.gt => date }] }
      ])
    }
    scope :expired, ->(date = Time.zone.now) {
      where('$or' => [
        { :activation_date.exists => true , :activation_date.gt => date },
        { :expiration_date.exists => true , :expiration_date.lt => date }
      ])
    }
  end

  def active?
    now = Time.zone.now
    return false if activation_date.present? && activation_date >= now
    return false if expiration_date.present? && expiration_date < now
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
end

