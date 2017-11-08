module Gws::Addon::Discussion
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :state, type: String, default: "public", overwrite: true
      field :released, type: DateTime

      permit_params :state, :released

      validates :state, presence: true
      validates :released, datetime: true
      after_validation :set_released, if: -> { state == "public" }

      scope :and_public, ->() { where(state: "public") }
      scope :and_closed, ->() { where(state: "closed") }
    end

    def updated_after_released?
      updated.to_i > created.to_i && updated.to_i > released.to_i
    end

    def state_options
      %w(public closed).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
    end

    private

    def set_released
      self.released ||= Time.zone.now
    end
  end
end
