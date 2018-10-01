module Gws::Addon::Portal::Portlet
  module Markdown
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :portal_text, type: String
      field :portal_text_type, type: String
      permit_params :portal_text, :portal_text_type
    end

    def portal_text_type_options
      [:plain, :markdown].map { |m| [I18n.t("ss.options.text_type.#{m}"), m] }
    end

    def portal_html
      return nil if portal_text.blank?
      if portal_text_type == 'markdown'
        SS::Addon::Markdown.text_to_html(portal_text)
      else
        ERB::Util.h(portal_text).gsub(/(\r\n?)|(\n)/, "<br />").html_safe
      end
    end
  end
end
