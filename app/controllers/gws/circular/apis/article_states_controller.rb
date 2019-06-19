class Gws::Circular::Apis::ArticleStatesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Circular::Post

  before_action :set_post
  before_action :set_group
  before_action :set_custom_group

  private

  def set_post
    @cur_post ||= Gws::Circular::Post.site(@cur_site).topic.find(params[:post_id])
  end

  def set_group
    if params[:s].present? && params[:s][:group].present?
      @group = @cur_site.descendants.active.find(params[:s][:group]) rescue nil
    else
      @group = @cur_site
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
    @group_ids ||= @cur_site.descendants.active.in_group(@group).pluck(:id)
  end

  public

  def index
    @items = @cur_post.sorted_overall_members.active
    if @custom_group.present?
      @items = @items.in(id: @custom_group.members.pluck(:id))
    end

    @items = @items.in(group_ids: group_ids).
      search(params[:s]).
      order_by_title(@cur_site).
      page(params[:page]).per(50)
  end
end
