module Opendata::ResourceReportBase
  extend ActiveSupport::Concern

  included do
    cattr_accessor :target_models, instance_accessor: false
    cattr_accessor :issued_at_field, instance_accessor: false
    cattr_accessor :report_model, instance_accessor: false
  end

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
    self.class.target_models.each do |model|
      each_item(model.all, &method(:update_result))
    end
  end

  def each_item(base_criteria, &block)
    criteria = base_criteria.site(site)
    criteria = criteria.exists(resource_source_url: false)
    criteria = criteria.gte(self.class.issued_at_field => @start_at).lt(self.class.issued_at_field => @end_at)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      # load at once
      items = criteria.in(id: ids).to_a
      # call callback with item
      items.each(&block)
    end
  end

  def bot?(item)
    user_agent = item.user_agent
    return false if user_agent.blank?

    browser = Browser.new(user_agent)
    browser.bot?
  end

  def update_result(item)
    return if bot?(item)

    issued_at = extract_issued_at(item)
    year = issued_at.year
    month = issued_at.month
    day = issued_at.day
    count_field = "day#{day - 1}_count".to_sym
    dataset_id = item.dataset_id
    resource_id = item.resource_id

    dataset_name = item.dataset_name.presence
    resource_name = item.resource_name.presence
    resource_filename = item.resource_filename.presence
    resource_format = item.resource_format.presence || item.resource_filename.try { |filename| filename.sub(/.*\./, "").upcase }

    dataset_url = item.full_url.presence
    dataset_areas = item.dataset_areas.presence
    dataset_categories = item.dataset_categories.presence
    dataset_estat_categories = item.dataset_estat_categories.presence

    found = @results.find do |item|
      next false unless item[:year] == year
      next false unless item[:month] == month
      next false unless item[:dataset_id] == dataset_id
      next false unless item[:dataset_name] == dataset_name
      next false unless item[:resource_id] == resource_id
      next false unless item[:resource_name] == resource_name

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
      dataset_estat_categories: dataset_estat_categories, resource_id: resource_id, resource_name: resource_name,
      resource_filename: resource_filename, resource_format: resource_format, count_field => 1
    }
  end

  def extract_issued_at(item)
    item.send(self.class.issued_at_field)
  end

  def update_reports
    @results.each do |item|
      year = item[:year]
      month = item[:month]
      dataset_id = item[:dataset_id]
      dataset_name = item[:dataset_name].presence
      resource_id = item[:resource_id]
      resource_name = item[:resource_name].presence

      conditions = {
        year_month: year * 100 + month, dataset_id: dataset_id, dataset_name: dataset_name,
        resource_id: resource_id, resource_name: resource_name
      }
      r = self.class.report_model.site(site).where(conditions).first_or_create
      r.dataset_url = item[:dataset_url].presence
      r.dataset_areas = item[:dataset_areas].presence
      r.dataset_categories = item[:dataset_categories].presence
      r.dataset_estat_categories = item[:dataset_estat_categories].presence
      r.resource_filename = item[:resource_filename].presence
      r.resource_format = item[:resource_format].presence

      31.times do |i|
        count_field = "day#{i}_count".to_sym
        r[count_field] = item[count_field] if item.key?(count_field)
      end

      r.save
    end
  end

  def available_dataset_and_resources
    @available_dataset_and_resources ||= begin
      available_dataset_and_resources = Opendata::Dataset.site(site).pluck(:id, "resources._id")
      available_dataset_and_resources.map! do |dataset_id, resources|
        if resources.blank?
          [ [ dataset_id, -1 ] ]
        else
          resources.map { |hash| [ dataset_id, hash["_id"] ] }
        end
      end
      available_dataset_and_resources.flatten!(1)
      available_dataset_and_resources
    end
  end

  # データセット/ リソースが DB に見つからなければ `deleted` をセットする
  def update_deleted
    year_month = @start_at.year * 100 + @start_at.month
    criteria = self.class.report_model.site(site).where(year_month: year_month).exists(deleted: false)

    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      items = criteria.in(id: ids).to_a
      items.each do |item|
        found = available_dataset_and_resources.find do |dataset_id, resource_id|
          item.dataset_id == dataset_id && item.resource_id == resource_id
        end
        next if found.present?

        msg = "report #{item.dataset_name}(#{item.dataset_id})/#{item.resource_name}(#{item.resource_id}): already deleted"
        Rails.logger.info msg
        self.class.report_model.site(site).where(dataset_id: item.dataset_id, resource_id: item.resource_id).set(deleted: @now)
      end
    end
  end

  # 履歴の存在しないデータセットとリソースを登録
  def add_datasets_with_no_history
    year_month = @start_at.year * 100 + @start_at.month

    each_dataset_and_resource_with_no_history do |dataset, resource|
      conditions = {
        year_month: year_month, dataset_id: dataset.id, dataset_name: dataset.name,
        resource_id: resource.id, resource_name: resource.name
      }

      r = self.class.report_model.site(site).where(conditions).first_or_create
      r.dataset_url = dataset.full_url.presence if r.dataset_url.blank?
      r.dataset_areas = dataset.areas.and_public.order_by(order: 1).pluck(:name) if r.dataset_areas.blank?
      r.dataset_categories = dataset.categories.and_public.order_by(order: 1).pluck(:name) if r.dataset_categories.blank?
      if r.dataset_estat_categories.blank?
        r.dataset_estat_categories = dataset.estat_categories.and_public.order_by(order: 1).pluck(:name)
      end
      r.resource_filename = resource.filename.presence if r.resource_filename.blank?
      r.resource_format = resource.format.presence if r.resource_format.blank?

      r.save
      Rails.logger.info "report #{r.id}: created without any count"
    end
  end

  def each_dataset_and_resource_with_no_history
    year_month = @start_at.year * 100 + @start_at.month
    criteria = self.class.report_model.site(site).where(year_month: year_month).exists(deleted: false)
    not_exist_ids = available_dataset_and_resources - criteria.pluck(:dataset_id, :resource_id)
    Rails.logger.info "found #{not_exist_ids.length.to_s(:delimited)} datasets/resources with no history"

    dataset_ids = not_exist_ids.map { |dataset_id, _resource_id| dataset_id }.uniq
    datasets = Opendata::Dataset.site(site).in(id: dataset_ids).to_a

    not_exist_ids.each do |dataset_id, resource_id|
      dataset = datasets.find { |dataset| dataset.id == dataset_id }
      next if dataset.blank?

      resource = dataset.resources.where(id: resource_id).first
      next if resource.blank?
      next if resource.source_url.present?

      yield dataset, resource
    end
  end
end
