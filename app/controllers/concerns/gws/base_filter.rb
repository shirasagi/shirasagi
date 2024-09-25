module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    self.user_class = Gws::User
    self.log_class = Gws::History

    helper Gws::LayoutHelper
    helper Gws::Presence::UserHelper
    helper Gws::PublicUserProfile
    helper Gws::ReadableSettingHelper

    before_action :validate_gws
    before_action :set_gws_assets
    before_action :set_current_site
    before_action :set_gws_logged_in, if: ->{ @cur_user }
    before_action :set_current_group, if: ->{ @cur_user }
    before_action :set_crumbs
    after_action :put_history_log, if: ->{ @cur_user }
    navi_view "gws/main/navi"
  end

  private

  # override SS::BaseFilter#logout_path
  def logout_path
    # グループウェア利用時、常に /.g?/logout がログアウトのパスとなるようにする
    @logout_path = gws_logout_path(site: @cur_site)
  end

  def validate_gws
    raise '404' if SS.config.gws.disable.present?
  end

  def set_gws_assets
    SS.config.gws.stylesheets.each { |path, options| options ? stylesheet(path, **options.symbolize_keys) : stylesheet(path) }
    SS.config.gws.javascripts.each { |path, options| options ? javascript(path, **options.symbolize_keys) : javascript(path) }
  end

  def set_current_site
    @ss_mode = :gws
    @cur_site = SS.current_site = Gws::Group.find(params[:site])
    @cur_user.cur_site = @cur_site if @cur_user
    @crumbs << [@cur_site.name, gws_portal_path]
  end

  def set_current_group
    @cur_group = SS.current_user_group = @cur_user.gws_default_group
    raise "403" unless @cur_group

    @cur_superior_users = @cur_user.gws_superior_users(@cur_site)
    @cur_superior_groups = @cur_user.gws_superior_groups(@cur_site)
  end

  def set_gws_logged_in
    gws_session = session[:gws]
    gws_session ||= {}
    gws_session[@cur_site.id.to_s] ||= {}
    gws_session[@cur_site.id.to_s]['last_logged_in'] ||= begin
      Gws::History.info!(
        :controller, @cur_user, @cur_site,
        path: SS.request_path(request), controller: self.class.name.underscore, action: action_name,
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
        path: SS.request_path(request), controller: self.class.name.underscore, action: action_name,
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
