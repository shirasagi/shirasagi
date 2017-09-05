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
    Cms::Part.plugins.select { |name, path, enabled| enabled }.map { |name, path, enabled| [name, path] }
  end

  def becomes_with_route(name = nil)
    super (name || route).sub("/", "/part/")
  end

  def mobile_view_options
    [
      [I18n.t('ss.options.state.show'), 'show'],
      [I18n.t('ss.options.state.hide'), 'hide'],
    ]
  end

  def ajax_view_options
    [
      [I18n.t('ss.options.state.enabled'), 'enabled'],
      [I18n.t('ss.options.state.disabled'), 'disabled'],
    ]
  end

  def ajax_html
    json = url.sub(/\.html$/, ".json")
    %(<a class="ss-part" data-href="#{json}">#{name}</a>)
  end

  # returns admin side show path
  def private_show_path(*args)
    model = "part"
    options = args.extract_options!
    methods = []
    if parent.blank?
      options = options.merge(site: site || cur_site, id: self)
      methods << "cms_#{model}_path"
    else
      options = options.merge(site: site || cur_site, cid: parent, id: self)
      methods << "node_#{model}_path"
    end

    helper_mod = Rails.application.routes.url_helpers
    methods.each do |method|
      path = helper_mod.send(method, *args, options) rescue nil
      return path if path.present?
    end

    nil
  end

  private

  def fix_extname
    ".part.html"
  end
end
