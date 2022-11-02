class Gws::Workload::Graph::Aggregation
  include Gws::Workload::Graph::AggregationTotal
  include Gws::Workload::Graph::AggregationCategory
  include Gws::Workload::Graph::AggregationCsv

  attr_reader :site, :year, :group
  attr_reader :categories, :loads, :clients, :cycles
  attr_reader :graph_users, :users
  attr_reader :items, :comments, :overtimes

  attr_reader :graph_user, :user
  attr_reader :category

  attr_reader :total_datasets, :worktime_datasets, :overtime_datasets, :client_datasets, :load_datasets

  def initialize(site, year, group, users)
    # base condition
    @site = site
    @year = year
    @group = group

    @graph_users = Gws::Workload::Graph::UserSetting.create_settings(users, site_id: site.id, group_id: group.id).
      and_show_graph.to_a
    @users = @graph_users.map(&:user)

    @categories = Gws::Workload::Category.site(site).member_group(group).search_year(year: year).to_a
    @loads = Gws::Workload::Load.site(site).search_year(year: year).and_show_graph.to_a
    @clients = Gws::Workload::Client.site(site).search_year(year: year).and_show_graph.to_a
    @cycles = Gws::Workload::Cycle.site(site).search_year(year: year).to_a

    # extra condition
    @category = nil
    @graph_user = nil
    @user = nil

    # base items
    @items = Gws::Workload::Work.none
    @comments = Gws::Workload::WorkComment.none
    @overtimes = Gws::Workload::Overtime.none

    # results
    @total_datasets = []
    @worktime_datasets = []
    @overtime_datasets = []
    @client_datasets = []
    @load_datasets = []
  end

  def months
    site.fiscal_months
  end

  def month_labels
    months.map { |m| "#{m}#{I18n.t("datetime.prompts.month")}" }
  end

  def set_graph_user(graph_user)
    @graph_user = graph_user
    @user = graph_user.user
    @graph_users = [graph_user]
  end

  def set_category(category)
    @category = category
  end

  def set_base_items
    @items = Gws::Workload::Work.site(site).without_deleted.reorder(due_start_on: 1)
    @items = @items.search_year(year: year)
    @items = @items.member_group(group)
    @items = @items.search_category_id(category_id: category.id) if category

    # 担当課の中の業務にてコメントしたもの
    @comments = Gws::Workload::WorkComment.site(site).and([
      { user_id: { "$in" => graph_users.map(&:user_id) } },
      { work_id: { "$in" => @items.pluck(:id) } },
      { worktime_minutes: { "$gt" => 0 } }
    ])

    @items = @items.member(@graph_user.user) if graph_user

    @overtimes = Gws::Workload::Overtime.create_settings(year, users,
      site_id: site.id, group_id: group.id)
  end
end
