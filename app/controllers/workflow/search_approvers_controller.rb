class Workflow::SearchApproversController < ApplicationController
  include Cms::ApiFilter

  model Cms::User

  before_action :set_group

  private
    def set_group
      if params[:s].present? && params[:s][:group].present?
        @group = Cms::Group.site(@cur_site).active.find(params[:s][:group])
      end
      @group ||= @cur_user.groups.active.first

      @groups = Cms::Group.site(@cur_site).active.tree_sort
    end

    def group_ids
      Cms::Group.site(@cur_site).active.in_group(@group).pluck(:id)
    end

  public
    def index
      @level = params[:level]
      criteria = @model.site(@cur_site).active.search(params[:s])
      criteria = criteria.in(group_ids: group_ids) if @group
      @items = criteria.order_by(_id: 1).page(params[:page]).per(50)
    end
end
