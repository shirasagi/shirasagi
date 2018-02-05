class Gws::Memo::ListMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::ListMessage

  navi_view 'gws/memo/management/navi'

  before_action :set_list
  before_action :set_crumbs

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

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_list: @cur_list }
  end

  public

  def index
    raise '403' unless @cur_list.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).and_list(@cur_list).and_list_message.
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    if params['commit'] == t('gws/memo/message.commit_params_check')
      raise '403' unless @item.allowed?(:send, @cur_user, site: @cur_site)
      @item.state = "public"
      notice = t("ss.notice.sent")
    else
      @item.state = "closed"
      notice = t("ss.notice.saved")
    end

    if @item.save
      # send_forward_mails
      render_create true, location: { action: :index }, notice: notice
    else
      render_create false, location: { action: :index }, notice: notice
    end
  end
end
