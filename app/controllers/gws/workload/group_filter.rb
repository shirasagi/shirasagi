module Gws::Workload::GroupFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_aggregation_groups
    before_action :set_selected_group
    before_action :set_categories
    helper_method :category_options, :group_options, :user_options
  end

  private

  def set_aggregation_groups
    active_at = @cur_site.fiscal_last_date(@year).change(hour: 23, min: 59)
    @aggregation_groups = Gws::Aggregation::Group.site(@cur_site).active_at(active_at)
  end

  def set_selected_group
    group_id = (params[:group] == "-") ? @cur_group.id : params[:group].to_i
    @aggregation_group = @aggregation_groups.find_group(group_id)

    if @aggregation_group
      @group = @aggregation_group.group
      @users = @aggregation_group.ordered_users
    else
      @group = Gws::Group.find(group_id) rescue nil
      raise "404" if @group.nil?
      @users = []
    end
  end

  def set_categories
    @categories = Gws::Workload::Category.site(@cur_site).member_group(@group).search_year(year: @year).to_a
    return if params[:category] == "-"
    @category = @categories.find { |c| c.id == params[:category].to_i }
    redirect_to(category: "-") if @category.nil?
  end

  def group_options
    @aggregation_groups.map { |g| { _id: g.group_id, name: g.name, trailing_name: g.trailing_name } }
  end

  def user_options
    [{ _id: "-", name: "// #{@model.t(:member_ids)}", trailing_name: "// #{@model.t(:member_ids)}" }] + @users.map { |u| { _id: u.id, name: u.name, trailing_name: u.name } }
  end

  def category_options
    @categories.map { |c| [c.name, c.id] }
  end
end
