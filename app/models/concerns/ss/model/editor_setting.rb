module SS::Model::EditorSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :color_button, type: String
    field :editor_css_path, type: String
    validates :color_button, inclusion: { in: %w(enabled disabled), allow_blank: true }
    permit_params :color_button, :editor_css_path
  end

  def color_button_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end
end
