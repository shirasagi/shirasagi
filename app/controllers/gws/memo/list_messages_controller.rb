class Gws::Memo::ListMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::ListMessage

  navi_view 'gws/memo/management/navi'

  before_action :set_list
  before_action :set_crumbs
  before_action :set_search_params
  helper_method :state_options

  private

  def set_list
    @cur_list ||= Gws::Memo::List.site(@cur_site).allow(:read, @cur_user, site: @cur_site).find(params[:list_id])
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('ss.management'), gws_memo_management_main_path ]
    @crumbs << [t('mongoid.models.gws/memo/list'), gws_memo_lists_path ]
    @crumbs << [@cur_list.name, action: :index ]
  end

  def set_search_params
    @s = params[:s] || {}
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_list: @cur_list }
  end

  def send_params
    { state: 'public', member_ids: @cur_list.overall_members.pluck(:id) }
  end

  def draft_params
    { state: 'closed' }
  end

  def state_options
    %w(closed public).map do |v|
      [ I18n.t("gws/memo.options.state.#{v}"), v ]
    end
  end

  public

  def index
    raise '403' unless @cur_list.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).and_list(@cur_list).and_list_message.
      allow(:read, @cur_user, site: @cur_site).
      search(@s).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    if params['commit'] == t('gws/memo/message.commit_params_check')
      raise '403' unless @item.allowed?(:send, @cur_user, site: @cur_site)
      @item.attributes = send_params
      notice = t("ss.notice.sent")
    else
      @item.attributes = draft_params
      notice = t("ss.notice.saved")
    end

    if @item.save
      # send_forward_mails
      render_create true, location: { action: :index }, notice: notice
    else
      render_create false, location: { action: :index }, notice: notice
    end
  end

  def update
    @item.attributes = get_params
    raise '404' unless @item.editable?(@cur_user, @cur_site)

    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if params['commit'] == t('gws/memo/message.commit_params_check')
      raise '403' unless @item.allowed?(:send, @cur_user, site: @cur_site)
      @item.attributes = send_params
      notice = t("ss.notice.sent")
    else
      @item.attributes = draft_params
      notice = t("ss.notice.saved")
    end

    if @item.update
      # send_forward_mails
      render_update true, location: { action: :index }, notice: notice
    else
      render_update false, location: { action: :index }, notice: notice
    end
  end
end
