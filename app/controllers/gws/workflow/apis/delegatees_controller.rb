class Gws::Workflow::Apis::DelegateesController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  append_view_path "app/views/workflow/search_approvers"

  before_action :set_groups
  before_action :set_search_params

  private

  def set_groups
    @private_group = @cur_user.gws_role_permit_any?(@cur_site, :agent_private_gws_workflow_files)
    @all_group = @cur_user.gws_role_permit_any?(@cur_site, :agent_all_gws_workflow_files)
    @only_private_group = @private_group && !@all_group

    @groups = @cur_site.descendants.active
    if @only_private_group
      @groups = @groups.in(id: @cur_user.group_ids)
    end
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
    if @s.group.present?
      @group = @groups.find(@s.group)
    else
      @group = @cur_user.groups.active.in_group(@cur_site).first
      @s.group = @group.id if @group
    end
  end

  public

  def index
    raise "404" if !@private_group && !@all_group

    @multi = params[:single].blank?

    criteria = @model.all.active.ne(id: @cur_user.id)
    if @only_private_group
      criteria = criteria.in(group_ids: @groups.pluck(:id))
    else
      criteria = criteria.site(@cur_site)
    end
    criteria = criteria.search(@s)
    criteria = criteria.in(group_ids: @groups.in_group(@group).pluck(:id))
    @items = criteria.order_by_title(@cur_site).page(params[:page]).per(50)

    @groups = @groups.tree_sort(root_name: @cur_site.name)
  end
end
