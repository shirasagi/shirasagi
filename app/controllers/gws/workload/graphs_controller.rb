class Gws::Workload::GraphsController < ApplicationController
  include Gws::BaseFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::GroupFilter

  model Gws::Workload::Work

  prepend_view_path "app/views/gws/workload/graphs"

  navi_view "gws/workload/main/navi"

  before_action :deny
  before_action :set_aggregation

  helper_method :allowed_self?, :allowed_other?

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t("gws/workload.tabs.graph"), url_for(action: :index) ]
  end

  def dropdowns
    %w(year group user)
  end

  def set_selected_group
    if allowed_other?
      super
      return
    end

    if params[:group] != "-"
      redirect_to(group: "-")
      return
    end

    super
    @aggregation_groups = @aggregation_groups.class.new([])
    @aggregation_groups << @aggregation_group if @aggregation_group
  end

  def deny
    raise "403" if !allowed_self?
  end

  def set_aggregation
    @aggregation = Gws::Workload::Graph::Aggregation.new(@cur_site, @year, @group, @users)
    @users = @aggregation.users

    return if params[:user] == "-"
    graph_user = @aggregation.graph_users.find { |graph_user| graph_user.user_id == params[:user].to_i }
    if graph_user.nil?
      redirect_to(user: "-" )
      return
    end
    @aggregation.set_graph_user(graph_user)
    @user = graph_user.user
  end

  public

  def allowed_self?
    Gws::Workload::Graph.allowed_self?(@cur_user, site: @cur_site)
  end

  def allowed_other?
    Gws::Workload::Graph.allowed_other?(@cur_user, site: @cur_site)
  end

  def index
    @category ? category_graphs : total_graphs
    render
  end

  def total_graphs
    @aggregation.set_base_items
    @aggregation.aggregate_total_datasets
    @aggregation.aggregate_worktime_datasets
    @aggregation.aggregate_overtime_datasets
  end

  def category_graphs
    @aggregation.set_category(@category)
    @aggregation.set_base_items
    @aggregation.aggregate_client_datasets
    @aggregation.aggregate_load_datasets
  end

  def download_works
    @aggregation.set_category(@category) if @category
    @aggregation.set_base_items

    filename = "#{Gws::Workload::Work.collection_name}_#{Time.zone.now.to_i}.csv"
    send_enum(
      @aggregation.aggregate_work_enum_csv,
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end

  def download_work_comments
    @aggregation.set_category(@category) if @category
    @aggregation.set_base_items

    filename = "#{Gws::Workload::WorkComment.collection_name}_#{Time.zone.now.to_i}.csv"
    send_enum(
      @aggregation.aggregate_work_comment_enum_csv,
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end
end
