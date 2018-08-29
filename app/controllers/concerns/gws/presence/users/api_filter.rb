module Gws::Presence::Users::ApiFilter
  extend ActiveSupport::Concern

  included do
    model Gws::User

    prepend_view_path "app/views/gws/presence/apis/users"

    skip_before_action :set_item

    before_action :set_groups
    before_action :set_editable_users
    before_action :set_manageable_users
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

  def set_groups
    @groups = @cur_site.root.to_a + @cur_site.root.descendants.to_a
  end

  def set_editable_users
    @editable_user_ids = [@cur_user.id] + @cur_user.presence_title_manageable_users.map(&:id)
  end

  def set_manageable_users
    @manage_all = Gws::UserPresence.allowed?(:manage_all, @cur_user, site: @cur_site)

    if Gws::UserPresence.allowed?(:manage_custom_group, @cur_user, site: @cur_site)
      custom_groups = Gws::CustomGroup.site(@cur_site).in(member_ids: @cur_user.id).to_a
      @custom_group_user_ids = custom_groups.map { |item| item.members.pluck(:id) }.flatten.uniq
    else
      @custom_group_user_ids = []
    end

    if Gws::UserPresence.allowed?(:manage_private, @cur_user, site: @cur_site)
      @group_user_ids = @cur_user.gws_default_group.users.pluck(:id)
    else
      @group_user_ids = []
    end

    @manageable_user_ids = (@editable_user_ids + @group_user_ids + @custom_group_user_ids).uniq
  end

  def set_user
    @user = @model.where(id: params[:id]).in(group_ids: @groups.pluck(:id)).first
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

    if @editable_user_ids.include?(@user.id)
      raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)
    elsif @group_user_ids.include?(@user.id)
      raise "403" unless Gws::UserPresence.allowed?(:manage_private, @cur_user, site: @cur_site)
    elsif @custom_group_user_ids.include?(@user.id)
      raise "403" unless Gws::UserPresence.allowed?(:manage_custom_group, @cur_user, site: @cur_site)
    else
      raise "403" unless Gws::UserPresence.allowed?(:manage_all, @cur_user, site: @cur_site)
    end

    @item = @user.user_presence(@cur_site) || Gws::UserPresence.new
    @item.cur_site = @cur_site
    @item.cur_user = @user

    @item.attributes = get_params
    if @item.update
      respond_to do |format|
        format.json { render json: user_presence_json, status: :ok, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end
end
