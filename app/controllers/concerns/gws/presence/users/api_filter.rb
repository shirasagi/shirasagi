module Gws::Presence::Users::ApiFilter
  extend ActiveSupport::Concern
  include Gws::Presence::Users::AuthFilter

  included do
    model Gws::User

    prepend_view_path "app/views/gws/presence/apis/users"

    skip_before_action :set_item
  end

  private

  def get_params
    params.permit(:presence_state, :presence_plan, :presence_memo)
  end

  def user_presence_json
    {
      id: @item.user_id,
      name: @item.user.name,
      presence_state: @item.state,
      presence_state_label: @item.label(:state),
      presence_state_style: @item.state_style,
      presence_plan: @item.plan,
      presence_memo: @item.memo,
      editable: (@manage_all || @manageable_user_ids.include?(@item.user_id)),
    }
  end

  def set_user
    @user = @model.active.where(id: params[:id]).in(group_ids: @groups.pluck(:id)).first
  end

  public

  def show
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)

    set_user
    raise "404" unless @user

    @items = [@user]
  end

  def update
    set_user
    raise "404" unless @user
    raise "403" unless editable_user?(@user)

    @item = @user.user_presence(@cur_site)
    @item.cur_site = @cur_site
    @item.cur_user = @user

    @item.attributes = get_params
    if @item.update
      respond_to do |format|
        format.json { render json: user_presence_json, status: :ok, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.json { render json: @item.errors.full_messages, status: :unprocessable_content, content_type: json_content_type }
      end
    end
  end
end
