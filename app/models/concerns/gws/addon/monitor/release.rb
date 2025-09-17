module Gws::Addon::Monitor
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Release

    included do
      self.default_release_state = "draft"
    end

    def state_options
      %w(draft public closed).map { |m| [I18n.t("gws/monitor.options.state.#{m}"), m] }
    end
  end
end
