module SS::Release
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    # rubocop:disable Style/ClassVars
    class_variable_set(:@@_hide_released_field, nil)
    # rubocop:enable Style/ClassVars

    cattr_accessor :default_release_state, :public_states
    self.default_release_state = "public"
    self.public_states = %w(public)

    field :state, type: String, default: ->{ self.class.default_release_state }, overwrite: true
    field :released, type: DateTime
    field :release_date, type: DateTime
    field :close_date, type: DateTime

    permit_params :state, :released
    permit_params :release_date, :close_date

    validates :state, presence: true
    validates :released, datetime: true
    validates :release_date, datetime: true
    validates :close_date, datetime: true
    validate :validate_release_date
    after_validation :set_released, if: -> { state == "public" }
  end

  module ClassMethods
    def released_field_shown?
      !class_variable_get(:@@_hide_released_field)
    end

    def and_public(date = Time.zone.now)
      all.where(state: { "$in" => self.public_states }, "$and" => [
        { "$or" => [{ release_date: nil }, { :release_date.lte => date }] },
        { "$or" => [{ close_date: nil }, { :close_date.gt => date }] },
      ])
    end

    def and_public_but_after_close_date(date = Time.zone.now)
      all.where(state: { "$in" => self.public_states }, close_date: { "$lte" => date })
    end

    def and_closed(date = Time.zone.now)
      conds = [
        { state: nil }, { state: { "$nin" => public_states } }, { :release_date.gt => date }, { :close_date.lte => date }
      ]
      all.where("$and" => [{ "$or" => conds }])
    end

    private

    def hide_released_field
      # rubocop:disable Style/ClassVars
      class_variable_set(:@@_hide_released_field, true)
      # rubocop:enable Style/ClassVars
    end
  end

  def closed?(date = Time.zone.now)
    return true if !self.class.public_states.include?(state)
    return true if release_date.present? && release_date > date
    return true if close_date.present? && close_date <= date

    false
  end

  def public?(date = Time.zone.now)
    !closed?(date)
  end

  def updated_after_released?
    updated.to_i > created.to_i && updated.to_i > released.to_i
  end

  def state_with_release_date(now = nil)
    now ||= Time.zone.now
    if self.class.public_states.include?(state) && close_date.present? && close_date < now
      I18n.t("ss.state.expired")
    elsif public?(now)
      if close_date.present? && close_date > now
        I18n.t("ss.state.public_with_close_date", close_date: I18n.l(close_date, format: :picker))
      else
        I18n.t("ss.state.public")
      end
    else
      if release_date.present? && release_date > now
        I18n.t("ss.state.closed_with_release_date", release_date: I18n.l(release_date, format: :picker))
      else
        I18n.t("ss.state.closed")
      end
    end
  end

  def state_options
    %w(public closed).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  private

  def validate_release_date
    self.released ||= release_date if respond_to?(:released)

    if close_date.present? && release_date.present? && release_date >= close_date
      errors.add :close_date, :greater_than, count: t(:release_date)
    end
  end

  def set_released
    self.released ||= Time.zone.now
  end
end
