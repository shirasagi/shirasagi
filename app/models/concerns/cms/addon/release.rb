module Cms::Addon
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon

    def state_options
      [
        [I18n.t('views.options.state.public'), 'public'],
        [I18n.t('views.options.state.closed'), 'closed'],
      ]
    end
  end
end
