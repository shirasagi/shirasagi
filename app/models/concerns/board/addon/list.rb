module Board::Addon
  module List
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      field :mode, type: String, default: "thread"
      permit_params :mode
    end

    def limit
      value = self[:limit].to_i
      (value < 1 || value > 1000) ? 10 : value
    end

    def mode_options
      [
        [I18n.t('board.options.mode.thread'), 'thread'],
        [I18n.t('board.options.mode.tree'), 'tree']
      ]
    end
  end
end
