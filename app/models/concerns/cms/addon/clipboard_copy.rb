module Cms::Addon::ClipboardCopy
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :clipboard_copy_target, type: String
    field :clipboard_copy_selector, type: String
    field :clipboard_display_name, type: String
    permit_params :clipboard_copy_target, :clipboard_copy_selector, :clipboard_display_name
    validates :clipboard_copy_target, inclusion: { in: %w(url css_selector), allow_blank: true }
    validates :clipboard_display_name, presence: false
  end

  def clipboard_copy_target_options
    %w(url css_selector).map do |v|
      [ I18n.t("cms.options.clipboard_copy_target.#{v}"), v ]
    end
  end
end
