module Cms::Addon
  module RedirectLink
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      save_url_handler = template_variable_handlers[:url]
      template_variable_handler :url do |*args|
        ret = redirect_link rescue nil
        SS.safe_encode_url(ret.presence) || save_url_handler.call(*args)
      end

      save_full_url_handler = template_variable_handlers[:full_url]
      template_variable_handler :full_url do |*args|
        ret = redirect_link rescue nil
        SS.safe_encode_url(ret.presence) || save_full_url_handler.call(*args)
      end
    end
  end
end
