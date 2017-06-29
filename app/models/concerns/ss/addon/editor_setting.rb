module SS::Addon::EditorSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :color_button, type: String
    validates :color_button, inclusion: { in: %w(enabled disabled), allow_blank: true }
    permit_params :color_button
  end

  def color_button_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end
end
