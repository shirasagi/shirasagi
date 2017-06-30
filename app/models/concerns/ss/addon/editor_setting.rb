module SS::Addon::EditorSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :color_button, type: String
    field :editor_css, type: String
    field :editor_css_path, type: String
    validates :color_button, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :editor_css, inclusion: { in: %w(enabled disabled), allow_blank: true }
    permit_params :color_button, :editor_css, :editor_css_path
  end

  def color_button_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def editor_css_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def editor_css_enabled?
    editor_css == 'enabled'
  end
end
