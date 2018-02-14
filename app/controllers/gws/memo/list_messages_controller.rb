class Gws::Memo::ListMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::ListMessage

  navi_view 'gws/memo/messages/navi'

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
    @crumbs << [t('mongoid.models.gws/memo/list'), gws_memo_lists_path ]
    @crumbs << [@cur_list.name, action: :index ]
  end

  def set_search_params
    @s = params[:s] || {}
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_list: @cur_list }
  end

  def permit_fields
    super - %i[in_request_mdn]
  end

  def send_params
    @capacity_over_members, valid_members = @cur_list.overall_members.to_a.partition do |user|
      @item.quota_over?(user, @cur_site)
    end

    {
      state: 'public',
      from_member_name: @cur_list.sender_name.presence || @cur_list.name,
      member_ids: valid_members.map(&:id),
      in_validate_presence_member: true,
      in_append_signature: true,
      in_skip_validates_sender_quota: true,
    }
  end

  def draft_params
    { state: 'closed', in_skip_validates_sender_quota: true }
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
    @item = @model.new get_params.merge(draft_params)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
  end

  def edit
    raise '404' if @item.public?
    super
  end

  def update
    @item.attributes = get_params.merge(draft_params)
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '404' if @item.public?
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.save
  end

  def destroy
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    fake_folder = OpenStruct.new({ :draft_box? => @item.draft?, :sent_box? => @item.public? })
    render_destroy @item.destroy_from_folder(@cur_user, fake_folder)
  end

  def publish
    set_item
    raise '404' if @item.public?
    raise '403' unless @item.allowed?(:send, @cur_user, site: @cur_site)

    if request.get?
      send_params
      return
    end

    @item.attributes = send_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    render_update @item.save, notice: t('ss.notice.sent'), render: { file: :publish }
  end

  def seen
    set_item
    raise '404' if @item.draft?
    raise '403' unless @item.allowed?(:send, @cur_user, site: @cur_site)

    @items = Gws::User.site(@cur_site).in(id: @item.member_ids).active.search(params[:s])
  end
end
