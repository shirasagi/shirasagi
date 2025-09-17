module Gws::Addon::Monitor
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Release

    def state_options
      %w(draft public closed).map { |m| [I18n.t("gws/monitor.options.state.#{m}"), m] }
    end
  end
end
