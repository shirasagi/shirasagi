module Gws::Addon::Memo
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::SanitizeHtml
  end
end
