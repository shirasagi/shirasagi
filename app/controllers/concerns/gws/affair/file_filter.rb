module Gws::Affair::FileFilter
  extend ActiveSupport::Concern

  private

  def pre_params
    # 規定の管理グループは所属グループの上位グループ
    if @cur_superior_groups.present?
      @set_default_groups = @cur_superior_groups
    end

    # 規定の管理ユーザーは自身と上司
    if @cur_superior_users.present?
      @set_default_users = [@cur_user] + @cur_superior_users
    end

    @default_readable_setting = proc do
      @item.readable_setting_range = 'select'

      # 既定の閲覧（回覧）グループは所属グループと、所属グループの上位グループ
      @item.readable_group_ids = @cur_user.group_ids
      @item.readable_group_ids += @cur_superior_groups.map(&:id) if @cur_superior_groups.present?

      # 既定の閲覧（回覧）ユーザーは自身と上司
      @item.readable_member_ids = [@cur_user.id]
      @item.readable_member_ids += @cur_superior_users.map(&:id) if @cur_superior_users.present?
    end

    super
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      and_state(params[:state], @cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  public

  def index
    set_items
  end

  def show
    raise '403' unless @item.readable?(@cur_user) || @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end
end
