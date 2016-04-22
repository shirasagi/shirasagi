class Gws::Workflow::SearchApproversController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  prepend_view_path "app/views/workflow/search_approvers"

  before_action :set_group

  private
    def set_group
      if params[:s].present? && params[:s][:group].present?
        @group = @cur_site.descendants.active.find(params[:s][:group])
      else
        @group = @cur_user.groups.active.in_group(@cur_site).first
      end

      @groups = @cur_site.descendants.active
    end

    def group_ids
      @cur_site.descendants.active.in_group(@group).pluck(:id)
    end

  public
    def index
      @level = params[:level]
      criteria = @model.site(@cur_site).active.search(params[:s])
      criteria = criteria.in(group_ids: group_ids) if @group
      @items = criteria.order_by_title(@cur_site).page(params[:page]).per(50)
    end
end
