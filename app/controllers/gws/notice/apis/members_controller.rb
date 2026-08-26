class Gws::Notice::Apis::MembersController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  before_action :set_post
  before_action :set_group
  before_action :set_custom_group

  private

  def set_post
    @cur_post ||= Gws::Notice::Post.site(@cur_site).find(params[:notice_id])
  end

  def set_group
    if params[:s].present? && params[:s][:group].present?
      @group = @cur_site.descendants.active.find(params[:s][:group]) rescue nil
    else
      @group = @cur_group
    end

    @group ||= @cur_site
  end

  def set_custom_group
    @custom_groups = Gws::CustomGroup.site(@cur_site).readable(@cur_user, site: @cur_site)

    custom_group_param = params.dig(:s, :custom_group)
    if custom_group_param.present?
      # カスタムグループが見つからない場合は、無視するより例外が発生する方がセキュリティ的な意味で良い
      @custom_group = @custom_groups.find(custom_group_param)
    end
  end

  def group_ids
    @group_ids ||= @cur_site.descendants_and_self.active.in_group(@group).pluck(:id)
  end

  def set_items
    @items ||= begin
      set_post
      set_group
      set_custom_group

      items = @cur_post.overall_readers.site(@cur_site).active
      if @custom_group.present?
        items = items.in(id: @custom_group.members.pluck(:id))
      end

      case params.dig(:s, :browsed_state)
      when 'read'
        items = items.in(id: @cur_post.browsed_user_ids)
      when 'unread'
        items = items.nin(id: @cur_post.browsed_user_ids)
      else # 'both'
        # nop
      end

      items.in(group_ids: group_ids)
    end
  end

  public

  def index
    set_items

    @items = @items.search(params[:s]).
      order_by_title(@cur_site).
      page(params[:page]).per(50)
  end
end
