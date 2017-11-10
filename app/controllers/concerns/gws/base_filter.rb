module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Gws::User }

    helper Gws::LayoutHelper

    before_action :validate_gws, if: ->{ SS.config.gws.disable.present? }
    before_action :set_gws_assets
    before_action :set_current_site
    before_action :validate_service, if: ->{ SS.config.service.gws_limitation.present? }
    before_action :set_current_group
    before_action :set_account_menu
    before_action :set_crumbs
    navi_view "gws/main/navi"
  end

  private

  def validate_gws
    raise '404'
  end

  def set_gws_assets
    SS.config.gws.stylesheets.each { |m| stylesheet(m) }
    SS.config.gws.javascripts.each { |m| javascript(m) }
  end

  def set_current_site
    @ss_mode = :gws
    @cur_site = Gws::Group.find params[:site]
    @cur_user.cur_site = @cur_site
    @crumbs << [@cur_site.name, gws_portal_path]
  end

  def validate_service
    return unless @account = Service::Account.where(organization_ids: @cur_site.id).first
    return if @account.gws_enabled?
    msg = [I18n.t("service.messages.disabled_app", name: @cur_site.name)]
    msg << I18n.t("service.messages.over_quota") if @account.gws_quota_over?
    render html: msg.join("<br />").html_safe
  end

  def set_current_group
    @cur_group = @cur_user.gws_default_group
    raise "403" unless @cur_group
  end

  def set_account_menu
    @account_menu = []
    @cur_user.groups.in_group(@cur_site).each do |group|
      next if @cur_user.gws_default_group.id == group.id
      @account_menu << [group.section_name, gws_default_group_path(default_group: group)]
    end
    @account_menu << [I18n.t("mongoid.models.gws/user_setting"), gws_user_setting_path]
  end

  def set_crumbs
    #
  end

  def current_site
    @cur_site
  end

  def current_group
    @cur_group
  end
end
