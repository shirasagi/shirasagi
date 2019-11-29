class Opendata::DatasetAccessReportJob < Cms::ApplicationJob
  def perform(*args)
    @now = Time.zone.now

    start_at = args.shift
    start_at = start_at ? Time.zone.parse(start_at) : @now.yesterday
    @start_at = start_at.beginning_of_day

    end_at = args.shift
    end_at = end_at ? Time.zone.parse(end_at) : @start_at
    @end_at = end_at.tomorrow.beginning_of_day

    build_results

    update_reports

    # 通常運用状態なら削除日時を更新する
    # それ以外（一括データ作成時など）では、削除日時は更新しない（別の/特注の削除日時設定パッチを実行してセットする）
    if @now.yesterday.to_date == @start_at.to_date
      update_deleted
      add_datasets_with_no_history
    end

    true
  end

  private

  def build_results
    @results = []
    each_item(&method(:update_result))
  end

  def each_item(&block)
    criteria = Recommend::History::Log.site(site).where(target_class: "Opendata::Dataset")
    criteria = criteria.gte(created: @start_at).lt(created: @end_at)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      # load at once
      items = criteria.in(id: ids).to_a
      # call callback with item
      items.each(&block)
    end
  end

  def available_datasets
    # load all datasets at once
    @available_datasets ||= Opendata::Dataset.site(site).to_a
  end

  def available_dataset_ids
    available_datasets.map(&:id)
  end

  def find_dataset(dataset_id)
    # find with Array#find
    available_datasets.find { |dataset| dataset.id == dataset_id }
  end

  def bot?(item)
    user_agent = item.user_agent
    return false if user_agent.blank?

    browser = Browser.new(user_agent)
    browser.bot?
  end

  def update_result(item)
    return if bot?(item)

    issued_at = item.created
    year = issued_at.year
    month = issued_at.month
    day = issued_at.day
    count_field = "day#{day - 1}_count".to_sym
    dataset_id = item.target_id.to_i
    dataset_url = item.access_url.presence

    dataset = find_dataset(dataset_id)
    if dataset
      dataset_name = dataset.name.presence
      dataset_areas = dataset.areas.and_public.order_by(order: 1).pluck(:name)
      dataset_categories = dataset.categories.and_public.order_by(order: 1).pluck(:name)
      dataset_estat_categories = dataset.estat_categories.and_public.order_by(order: 1).pluck(:name)
    end
    dataset_name ||= I18n.t("ss.options.state.deleted")

    found = @results.find do |item|
      next false unless item[:year] == year
      next false unless item[:month] == month
      next false unless item[:dataset_id] == dataset_id
      next false unless item[:dataset_name] == dataset_name

      true
    end

    if found
      found[count_field] ||= 0
      found[count_field] += 1

      if found[:issued_at] < issued_at
        found[:dataset_url] = dataset_url
        found[:dataset_areas] = dataset_areas
        found[:dataset_categories] = dataset_categories
        found[:dataset_estat_categories] = dataset_estat_categories
      end

      return
    end

    @results << {
      issued_at: issued_at, year: year, month: month, dataset_id: dataset_id, dataset_name: dataset_name,
      dataset_url: dataset_url, dataset_areas: dataset_areas, dataset_categories: dataset_categories,
      dataset_estat_categories: dataset_estat_categories, count_field => 1
    }
  end

  def update_reports
    @results.each do |item|
      year = item[:year]
      month = item[:month]
      dataset_id = item[:dataset_id]
      dataset_name = item[:dataset_name].presence

      conditions = { year_month: year * 100 + month, dataset_id: dataset_id, dataset_name: dataset_name }
      r = Opendata::DatasetAccessReport.site(site).where(conditions).first_or_create
      r.dataset_url = item[:dataset_url].presence
      r.dataset_areas = item[:dataset_areas].presence
      r.dataset_categories = item[:dataset_categories].presence
      r.dataset_estat_categories = item[:dataset_estat_categories].presence

      31.times do |i|
        count_field = "day#{i}_count".to_sym
        r[count_field] = item[count_field] if item.key?(count_field)
      end

      r.save
    end
  end

  def each_report(conditions, &block)
    criteria = Opendata::DatasetAccessReport.site(site).where(conditions)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      # load all reports at once
      reports = criteria.in(id: ids).to_a

      # call callback with report
      reports.each(&block)
    end
  end

  # データセット/ リソースが DB に見つからなければ `deleted` をセットする
  def update_deleted
    year_month = @start_at.year * 100 + @start_at.month

    each_report(year_month: year_month, :deleted.exists => false) do |item|
      found = find_dataset(item.dataset_id)
      next if found.present?

      Rails.logger.info "report #{item.dataset_name}(#{item.dataset_id}): already deleted"
      Opendata::DatasetAccessReport.site(site).where(dataset_id: item.dataset_id).set(deleted: @now)
    end
  end

  # 履歴の存在しないデータセットを登録
  def add_datasets_with_no_history
    year_month = @start_at.year * 100 + @start_at.month
    criteria = Opendata::DatasetAccessReport.site(site).where(year_month: year_month).exists(deleted: false)
    dataset_ids = available_dataset_ids - criteria.pluck(:dataset_id)
    Rails.logger.info "found #{dataset_ids.length.to_s(:delimited)} datasets with no history"

    dataset_ids.each do |dataset_id|
      dataset = find_dataset(dataset_id)
      next if dataset.blank?

      conditions = { year_month: year_month, dataset_id: dataset_id, dataset_name: dataset.name }
      r = Opendata::DatasetAccessReport.site(site).where(conditions).first_or_create
      r.dataset_url = dataset.full_url.presence if r.dataset_url.blank?
      r.dataset_areas = dataset.areas.and_public.order_by(order: 1).pluck(:name) if r.dataset_areas.blank?
      r.dataset_categories = dataset.categories.and_public.order_by(order: 1).pluck(:name) if r.dataset_categories.blank?
      if r.dataset_estat_categories.blank?
        r.dataset_estat_categories = dataset.estat_categories.and_public.order_by(order: 1).pluck(:name)
      end

      r.save
      Rails.logger.info "report #{r.id}: created without any count"
    end
  end
end
