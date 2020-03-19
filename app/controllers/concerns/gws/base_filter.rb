module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Gws::User }

    self.log_class = Gws::History

    helper Gws::LayoutHelper
    helper Gws::Presence::UserHelper

    before_action :validate_gws
    before_action :set_gws_assets
    before_action :set_current_site
    before_action :set_gws_logged_in, if: ->{ @cur_user }
    before_action :set_current_group, if: ->{ @cur_user }
    before_action :set_account_menu, if: ->{ @cur_user }
    before_action :set_crumbs
    after_action :put_history_log, if: ->{ @cur_user }
    navi_view "gws/main/navi"
  end

  private

  def validate_gws
    raise '404' if SS.config.gws.disable.present?
  end

  def set_gws_assets
    SS.config.gws.stylesheets.each { |m| stylesheet(m) }
    SS.config.gws.javascripts.each { |m| javascript(m) }
  end

  def set_current_site
    @ss_mode = :gws
    @cur_site = Gws::Group.find params[:site]
    @cur_user.cur_site = @cur_site if @cur_user
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

  def set_gws_logged_in
    gws_session = session[:gws]
    gws_session ||= {}
    gws_session[@cur_site.id.to_s] ||= {}
    gws_session[@cur_site.id.to_s]['last_logged_in'] ||= begin
      Gws::History.info!(
        :controller, @cur_user, @cur_site,
        path: request.path, controller: self.class.name.underscore, action: action_name,
        model: Gws::User.name.underscore, item_id: @cur_user.id, mode: 'login', name: @cur_user.name
      ) rescue nil
      Time.zone.now.to_i
    end

    session[:gws] = gws_session
  end

  # override SS::BaseFilter#rescue_action
  def rescue_action(exception)
    if exception.to_s.numeric?
      status = exception.to_s.to_i
    else
      status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
    end

    if status >= 500
      history_method = :error!
    elsif status >= 400
      history_method = :warn!
    end

    if history_method
      Gws::History.send(
        history_method, :controller, @cur_user, @cur_site,
        path: request.path, controller: self.class.name.underscore, action: action_name,
        message: "#{exception.class} (#{exception.message})"
      ) rescue nil
    end

    super
  end

  def set_crumbs
    # override by subclass if necessary
  end

  def current_site
    @cur_site
  end

  def current_group
    @cur_group
  end

  def set_tree_navi
    @tree_navi = gws_share_apis_folder_list_path(id: params[:folder], type: params[:controller], category: params[:category])
  end
end
