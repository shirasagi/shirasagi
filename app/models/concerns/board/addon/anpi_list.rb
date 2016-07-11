module Board::Addon
  module AnpiList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      field :show_email, type: String
      validates :show_email, inclusion: { in: %w(enabled disabled) }, if: ->{ show_email.present? }
      permit_params :show_email
    end

    def show_email?
      show_email == 'enabled'
    end

    def show_email_options
      %w(enabled disabled).map { |m| [ I18n.t("board.options.show_email.#{m}"), m ] }.to_a
    end
  end
end
