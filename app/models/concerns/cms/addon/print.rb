module Cms::Addon::ClipboardCopy
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :print_display_name, type: String
    permit_params :print_display_name
    validates :print_display_name, presence: false
  end
end
