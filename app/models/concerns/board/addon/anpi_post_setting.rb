module Board::Addon
  module AnpiPostSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :text_size_limit, type: Integer, default: 100
      field :show_email, type: String
      field :deny_ips, type: SS::Extensions::Words

      validates :text_size_limit, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 400 }
      validates :show_email, inclusion: { in: %w(enabled disabled) }, if: ->{ show_email.present? }

      permit_params :text_size_limit, :show_email, :deny_ips
    end

    def show_email?
      show_email == 'enabled'
    end

    def text_size_limit_options
      [400, 200, 100, 0].map { |m| [ I18n.t("board.options.text_size_limit.l#{m}"), m ] }.to_a
    end

    def show_email_options
      %w(enabled disabled).map { |m| [ I18n.t("board.options.show_email.#{m}"), m ] }.to_a
    end
  end
end
