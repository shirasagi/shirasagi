module SS::BootstrapSupport::UrlHelper
  extend ActiveSupport::Concern
  include SS::BootstrapSupport::Common

  def link_to(name = nil, options = nil, html_options = nil, &block)
    if html_options
      html_options = html_options.with_indifferent_access
      css_class = bt_sup_normalize_css_class(html_options[:class])
      if bt_sup_include_btn_only?(css_class)
        css_class << 'btn-outline'
        html_options[:class] = css_class
      end
    end

    super(name, options, html_options, &block)
  end
end
