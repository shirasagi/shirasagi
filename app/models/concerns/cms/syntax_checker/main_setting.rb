module Cms::SyntaxChecker::MainSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :syntax_check, type: String
    validates :syntax_check, inclusion: { in: %w(enabled disabled), allow_blank: true }
  end

  def syntax_check_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def syntax_check_enabled?
    syntax_check != 'disabled'
  end
end
