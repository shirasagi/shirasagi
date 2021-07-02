module SS::Addon
  module SourceCleaner::SiteSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :source_cleaner_unwrap_tag_state, type: String, default: "enabled"
      field :source_cleaner_remove_tag_state, type: String, default: "enabled"
      field :source_cleaner_remove_class_state, type: String, default: "enabled"
      permit_params :source_cleaner_unwrap_tag_state, :source_cleaner_remove_tag_state, :source_cleaner_remove_class_state
    end

    def source_cleaner_unwrap_tag_state_options
      %w(disabled enabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }
    end
    alias source_cleaner_remove_tag_state_options source_cleaner_unwrap_tag_state_options
    alias source_cleaner_remove_class_state_options source_cleaner_unwrap_tag_state_options
  end
end
