module Cms::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Cms::User }

    helper Cms::NodeHelper
    helper Cms::FormHelper
    helper Map::MapHelper
    helper Cms::SnsHelper
    before_action :validate_cms
    before_action :set_cms_assets
    before_action :set_site
    before_action :set_cms_logged_in, if: ->{ @cur_user }
    before_action :validate_service, if: ->{ SS.config.service.cms_limitation.present? }
    before_action :set_node
    before_action :set_group, if: ->{ @cur_user }
    before_action :set_crumbs
  end

  private

  def validate_cms
    raise '404' if SS.config.cms.disable.present?
  end

  def set_cms_assets
    if SS.config.cms.stylesheets.present?
      SS.config.cms.stylesheets.each { |path, options| options ? stylesheet(path, **options.symbolize_keys) : stylesheet(path) }
    end
    if SS.config.cms.javascripts.present?
      SS.config.cms.javascripts.each { |path, options| options ? javascript(path, **options.symbolize_keys) : javascript(path) }
    end
  end

  def set_site
    @cur_site = SS.current_site = Cms::Site.find(params[:site])
    @ss_mode = :cms
    SS.reset_locale_and_timezone # cms and webmail are currently not supported.

    if @cur_site.maintenance_mode? && !@cur_site.allowed_maint_user?(@cur_user.id)
      @ss_maintenance_mode = true
      render "cms/maintenance_mode_notice/index", layout: "ss/base"
      return
    end

    request.env["ss.site"] = @cur_site
    @crumbs << [@cur_site.name, cms_contents_path]
  end

  def set_cms_logged_in
    cms_session = session[:cms]
    cms_session ||= {}
    cms_session[@cur_site.id.to_s] ||= {}
    cms_session[@cur_site.id.to_s]['last_logged_in'] ||= begin
      self.class.log_class.create_log!(
        request, response,
        controller: params[:controller], action: 'login',
        cur_site: @cur_site, cur_user: @cur_user, item: @cur_site
      ) rescue nil
      Time.zone.now.to_i
    end

    session[:cms] = cms_session
  end

  def validate_service
    return unless @account = Service::Account.any_in(organization_ids: @cur_site.group_ids).first
    return if @account.cms_enabled?
    msg = [I18n.t("service.messages.disabled_app", name: @cur_site.name)]
    msg << I18n.t("service.messages.over_quota") if @account.cms_quota_over?
    render html: msg.join("<br />").html_safe
  end

  def set_node
    return if params[:cid].blank? || params[:cid].to_s == "-"
    @cur_node = Cms::Node.site(@cur_site).find params[:cid]
    @cur_node.parents.each { |node| @crumbs << [node.name, view_context.contents_path(node)] }
    @crumbs << [@cur_node.name, view_context.contents_path(@cur_node)]
  end

  def set_group
    names = @cur_site.groups.active.pluck(:name).map { |name| /^#{::Regexp.escape(name)}(\/|$)/ }
    cur_groups = @cur_user.groups.active.in(name: names)
    @cur_group = SS.current_user_group = cur_groups.first # select one group
    raise "403" unless @cur_group
  end

  def set_crumbs
  end

  def set_tree_navi
    @tree_navi = cms_apis_node_tree_path(id: (@cur_node || 0), type: @model.to_s.underscore)
  end
end
