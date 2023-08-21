module Cms::Model::Part
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content

  included do
    include Cms::Model::PartDiscriminatorRetrieval

    cattr_accessor(:ajax_view_only, instance_accessor: false) { false }

    store_in collection: "cms_parts"
    set_permission_name "cms_parts"

    field :route, type: String
    field :mobile_view, type: String, default: "show"
    field :ajax_view, type: String, default: "disabled"
    field :ajax_view_expire_seconds, type: Integer
    permit_params :mobile_view, :ajax_view, :ajax_view_expire_seconds

    before_save :set_view_options

    liquidize do
      export as: :html do |context|
        if ajax_view == "enabled" && !context.registers[:mobile] && !context.registers[:preview]
          next self.ajax_html
        end

        next self.html if self.route == "cms/free"

        options = {
          cur_site: cur_site,
          cur_page: context.registers[:cur_page],
          cur_path: context.registers[:cur_path],
          cur_main_path: context.registers[:cur_main_path],
          cur_date: context.registers[:cur_date]
        }
        agent = Cms::PartAgent.attach(self, options)
        resp = context["parts"].in_render(self) do
          agent.render
        end
        resp.body
      end
    end
  end

  def route_options
    Cms::Part.plugins.select { |plugin| plugin.enabled? }.map { |plugin| [plugin.name, plugin.path] }
  end

  def route_label
    Cms::Part.plugins.find { |plugin| plugin.path == route }.try(:name)
  end

  def becomes_with_route(name = nil)
    return self if name.blank?

    name = name.sub("/", "/part/")
    return self if route == name

    super name
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

  def ajax_view_cache_enabled?
    ajax_view == "enabled" && ajax_view_expire_seconds.to_i > 0
  end

  def ajax_view_cache_key
    "ss-part/#{cache_key}"
  end

  # returns admin side show path
  def private_show_path(*args)
    model = "part"
    options = args.extract_options!
    methods = []
    if parent.blank?
      options = options.merge(site: cur_site || site, id: self)
      methods << "cms_#{model}_path"
    else
      options = options.merge(site: cur_site || site, cid: parent, id: self)
      methods << "node_#{model}_path"
    end

    helper_mod = Rails.application.routes.url_helpers
    methods.each do |method|
      path = helper_mod.send(method, *args, options) rescue nil
      return path if path.present?
    end

    nil
  end

  def root_owned?(user)
    true
  end

  private

  def set_view_options
    return unless self.class.ajax_view_only
    self.ajax_view = "enabled"
  end

  def fix_extname
    ".part.html"
  end
end
