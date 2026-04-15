class Gws::Workflow2::Apis::DelegateesController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  append_view_path "app/views/workflow/search_approvers"

  before_action :set_groups
  before_action :set_search_params

  private

  def set_groups
    @groups = @cur_site.descendants_and_self.active
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
    raise "404" unless @cur_site.menu_workflow2_visible?
    raise "404" unless Gws.module_usable?(:workflow2, @cur_site, @cur_user)

    @multi = params[:single].blank?

    criteria = @model.all.active.ne(id: @cur_user.id)
    criteria = criteria.site(@cur_site)
    criteria = criteria.search(@s)
    criteria = criteria.in(group_ids: @groups.in_group(@group).pluck(:id))
    @items = criteria.order_by_title(@cur_site).page(params[:page]).per(50)
  end
end
