module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Gws::User }

    helper Gws::LayoutHelper

    before_action :set_gws_assets
    before_action :set_current_site
    before_action :set_current_group
    before_action :set_account_menu
    before_action :set_crumbs
    navi_view "gws/main/navi"
  end

  private

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
