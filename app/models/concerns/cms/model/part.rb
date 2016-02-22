module Cms::Model::Part
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content

  included do |mod|
    store_in collection: "cms_parts"
    set_permission_name "cms_parts"

    field :route, type: String
    field :mobile_view, type: String, default: "show"
    field :ajax_view, type: String, default: "disabled"
    permit_params :mobile_view, :ajax_view
  end

  def route_options
    Cms::Part.plugins
  end

  def becomes_with_route(name = nil)
    super (name || route).sub("/", "/part/")
  end

  def mobile_view_options
    [
      [I18n.t('views.options.state.show'), 'show'],
      [I18n.t('views.options.state.hide'), 'hide'],
    ]
  end

  def ajax_view_options
    [
      [I18n.t('views.options.state.enabled'), 'enabled'],
      [I18n.t('views.options.state.disabled'), 'disabled'],
    ]
  end

  def ajax_html
    json = url.sub(/\.html$/, ".json")
    %(<a class="ss-part" data-href="#{json}">#{name}</a>)
  end

  private
    def fix_extname
      ".part.html"
    end
end
