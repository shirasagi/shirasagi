class Workflow::SearchApproversController < ApplicationController
  include Cms::ApiFilter

  model Cms::User

  before_action :set_group

  private

  def set_group
    if params[:s].present? && params[:s][:group].present?
      @group = Cms::Group.site(@cur_site).active.find(params[:s][:group])
    end
    @group ||= Cms::Group.site(@cur_site).in(id: @cur_user.group_ids).active.first

    @groups = Cms::Group.site(@cur_site).active.tree_sort
  end

  def group_ids
    Cms::Group.site(@cur_site).active.in_group(@group).pluck(:id)
  end

  public

  def index
    @level = params[:level]
    @approver_ids = params[:approver_ids].to_a.map(&:to_i)

    criteria = @model.site(@cur_site).active.search(params[:s])
    criteria = criteria.in(id: @approver_ids) if @approver_ids.present?
    criteria = criteria.in(group_ids: group_ids) if @group
    @items = criteria.order_by(_id: 1).page(params[:page]).per(50)
  end
end
