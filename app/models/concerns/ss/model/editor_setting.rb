module SS::Model::EditorSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :color_button, type: String
    field :editor_css_path, type: String

    validates :color_button, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :editor_css_path, url: { absolute_path: true, only_path: true, allow_blank: true }
    validate :encode_editor_css_path

    permit_params :color_button, :editor_css_path
  end

  def color_button_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def effective_editor_css_path
    return unless UrlValidator.valid?(editor_css_path, absolute_path: true, only_path: true)
    editor_css_path
  end

  private

  def encode_editor_css_path
    return unless editor_css_path_changed?
    return if errors[:editor_css_path].present?
    self.editor_css_path = SS.follow_up_url_encode!(editor_css_path)
  rescue => e
    Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    errors.add :editor_css_path, :url
  end
end
