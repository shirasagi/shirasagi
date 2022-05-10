class Gws::Notice::Apis::MembersController < ApplicationController
  include Gws::ApiFilter

  model Gws::Notice::Post

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
    @groups = @cur_site.descendants.active.tree_sort(root_name: @cur_site.name)
  end

  def set_custom_group
    @custom_groups = Gws::CustomGroup.site(@cur_site).readable(@cur_user, site: @cur_site)

    if params[:s].present? && params[:s][:custom_group].present?
      @custom_group = Gws::CustomGroup.site(@cur_site).find(params[:s][:custom_group]) rescue nil
    end
  end

  def group_ids
    @group_ids ||= @cur_site.descendants_and_self.active.in_group(@group).pluck(:id)
  end

  public

  def index
    @items = @cur_post.overall_readers.site(@cur_site).active
    if @custom_group.present?
      @items = @items.in(id: @custom_group.members.pluck(:id))
    end
    case params.dig(:s, :browsed_state)
    when 'read'
      @items = @items.in(id: @cur_post.browsed_user_ids)
    when 'unread'
      @items = @items.nin(id: @cur_post.browsed_user_ids)
    end

    @items = @items.in(group_ids: group_ids).
      search(params[:s]).
      order_by_title(@cur_site).
      page(params[:page]).per(50)
  end
end
