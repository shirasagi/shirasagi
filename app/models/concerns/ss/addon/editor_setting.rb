module SS::Addon::EditorSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :color_button, type: String
    field :editor_css_path, type: String
    field :syntax_check, type: String
    validates :color_button, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :syntax_check, inclusion: { in: %w(enabled disabled), allow_blank: true }
    permit_params :color_button, :editor_css_path, :syntax_check
  end

  def color_button_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def syntax_check_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def syntax_check_enabled?
    return false if Cms::WordDictionary.to_config[:replace_words].blank?
    syntax_check == 'enabled' || syntax_check.blank?
  end
end
