module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  # 「設定」モジュール（旧「標準機能」）のサイドメニュー（conf_navi 系）を表示する
  # コントローラの navi_view 一覧。これらのページに限り、パンくずへ「設定」階層を挿入する。
  # 判定を navi_view に紐付けることで、設定モジュールのコントローラが増えても
  # この一覧に追記するだけで追従できる。
  SETTINGS_NAVI_VIEWS = %w(
    gws/main/conf_navi
    gws/user_conf/navi
    gws/histories/navi
    gws/search_form/main/conf_navi
    gws/job/main/conf_navi
    gws/ldap/main/navi
    gws/tabular/gws/main/conf_navi
    gws/elasticsearch/diagnostic/main/conf_navi
  ).freeze

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
    # SS::BaseFilter#set_model の呼び出しはここ。set_current_site の後ろで set_crumbs の前
    before_action :set_model
    before_action :set_crumbs
    # 各コントローラの set_crumbs で機能名 crumb が積まれた「後」に実行し、
    # site crumb の直後へ「設定」を挿入する（set_conf_crumb 参照）。
    before_action :set_conf_crumb
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

  # 「設定」モジュール配下のページのパンくずに「設定」階層を挿入する。
  #
  # Gws::BaseFilter は全 GWS コントローラが include するため、無条件に挿入すると
  # スケジュールやお知らせなど設定と無関係なページのパンくずにまで「設定」が
  # 混入してしまう。そこで navi_view_file が設定系メニュー（SETTINGS_NAVI_VIEWS）
  # のときに限定して挿入する。
  #
  # set_crumbs の後に実行され、site crumb の直後（index 1）へ挿入するため、
  # 1 階層メニューは「サイト名 > 設定 > 機能」、多階層メニューは
  # 「サイト名 > 設定 > 機能 > …」の並びになる。
  # ラベルはサイドメニュー見出しと同じ gws.site_config（設定 / Settings）を用い、
  # 「設定」のランディングページは存在しないためリンク無し（プレーンテキスト）とする。
  def set_conf_crumb
    return unless SETTINGS_NAVI_VIEWS.include?(navi_view_file)
    return if @crumbs.blank?
    @crumbs.insert(1, [t("gws.site_config")])
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
