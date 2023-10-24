# frozen_string_literal: true

class Cms::GenerationReportCreateJob < Cms::ApplicationJob
  include Job::SS::Binding::Task

  self.task_class = Cms::Task

  def perform
    if !::File.exist?(task.perf_log_file_path) || ::File.size(task.perf_log_file_path).zero?
      Rails.logger.info { "#{task.perf_log_file_path} is not found" }
      return
    end

    title
    Rails.logger.tagged(::File.basename(task.perf_log_file_path)) do
      Zlib::GzipReader.open(task.perf_log_file_path) do |gz|
        gz.each_line do |line|
          line.strip!
          performance_info = JSON.parse(line)
          import_performance_info(performance_info)
        end
      end

      aggregate_histories
    rescue => e
      Rails.logger.error { e.to_s }
      raise
    end
  end

  private

  def generation_type
    @generation_type ||= begin
      case task.name
      when "cms:generate_pages"
        :page
      when "cms:generate_nodes"
        :node
      end
    end
  end

  def title
    @title ||= create_title!
  end

  def pending_relation
    @pending_relation ||= {}
  end

  def id_part_map
    @id_part_map ||= Cms::Part.all.site(site).to_a.index_by(&:id)
  end

  def id_layout_map
    @id_layout_map ||= Cms::Layout.all.site(site).to_a.index_by(&:id)
  end

  def id_page_map
    @id_page_map ||= Cms::Page.all.site(site).to_a.index_by(&:id)
  end

  def id_node_map
    @id_node_map ||= Cms::Node.all.site(site).to_a.index_by(&:id)
  end

  def create_title!
    title_name = "Performance Report at #{I18n.l(task.started, format: :long)}"
    if generation_type
      title_name = "Pages Generation #{title_name}"
    else
      title_name = "Nodes Generation #{title_name}"
    end
    title = Cms::GenerationReport::Title.new(
      cur_site: site, name: title_name, task: task, sha256_hash: Cms::GenerationReport.sha256_hash(task.perf_log_file_path))
    title.save!
    title
  end

  def import_performance_info(performance_info)
    content = find_content(performance_info)
    return unless content

    history = Cms::GenerationReport::History[title].new(
      cur_site: site, site: site, task: task, title: title, history_type: performance_info["type"],
      content: content, content_name: performance_info["name"], content_filename: performance_info["filename"],
      db: performance_info["db"], view: performance_info["view"], elapsed: performance_info["elapsed"],
      total_db: performance_info["db"], total_view: performance_info["view"], total_elapsed: performance_info["elapsed"])
    history.save!

    pending_histories = pending_relation.delete(performance_info.slice("type", "id"))
    if pending_histories.present?
      pending_histories.each do |pending_history|
        pending_history.update(parent: history)
      end

      history.child_ids = pending_histories.map(&:id)
      sub_total_db, sub_total_view, sub_total_elapsed = sub_total(history.child_ids)

      history.sub_total_db = sub_total_db
      history.sub_total_view = sub_total_view
      history.sub_total_elapsed = sub_total_elapsed
      history.db -= sub_total_db if sub_total_db
      history.view -= sub_total_view if sub_total_view
      history.elapsed -= sub_total_elapsed if sub_total_elapsed
      history.save!
    end

    scope = performance_info["scopes"].try(:last)
    if scope.present?
      scope = scope.slice("type", "id")
      pending_relation[scope] ||= []
      pending_relation[scope] << history
    end
  end

  def find_content(performance_info)
    case performance_info["type"]
    when "header"
      # ignore
    when "part"
      content = id_part_map[performance_info["id"]]
    when "page"
      content = id_page_map[performance_info["id"]]
    when "node"
      content = id_node_map[performance_info["id"]]
    when "layout"
      content = id_layout_map[performance_info["id"]]
    when "site"
      if performance_info["id"] == site.id
        content = site
      end
    else
      Rails.logger.debug { "#{performance_info["type"]}: unknown type" }
    end
    content
  end

  def aggregate_histories
    stages = []
    stages << AGGREGATE_HISTORIES_GROUP_STAGE
    stages << AGGREGATE_HISTORIES_ADD_FIELDS_STAGE

    results = Cms::GenerationReport::History[title].collection.aggregate(stages)
    results.to_a.each do |result|
      # 複数回レンダリングされるパーツとレイアウトは集計する意味があるが、通常1度しかレンダリングされないページとノードは集計する意味がない
      next unless %(part layout).include?(result["_id"]["history_type"])

      aggregation = Cms::GenerationReport::Aggregation[title].new(
        cur_site: site, site: site, task: task, title: title, history_type: result["_id"]["history_type"],
        content_id: result["_id"]["content_id"], content_type: result["_id"]["content_type"],
        content_name: result["_id"]["content_name"], content_filename: result["_id"]["content_filename"], count: result["count"],
        db: result["db"], view: result["view"], elapsed: result["elapsed"],
        total_db: result["total_db"], total_view: result["total_view"], total_elapsed: result["total_elapsed"],
        sub_total_db: result["sub_total_db"], sub_total_view: result["sub_total_view"],
        sub_total_elapsed: result["sub_total_elapsed"],
        average_db: result["average_db"], average_view: result["average_view"], average_elapsed: result["average_elapsed"],
        average_total_db: result["average_total_db"], average_total_view: result["average_total_view"],
        average_total_elapsed: result["average_total_elapsed"],
        average_sub_total_db: result["average_sub_total_db"], average_sub_total_view: result["average_sub_total_view"],
        average_sub_total_elapsed: result["average_sub_total_elapsed"]
      )
      aggregation.save!
    end
  end

  AGGREGATE_HISTORIES_GROUP_STAGE = {
    "$group" => {
      _id: {
        history_type: "$history_type",
        content_id: "$content_id",
        content_type: "$content_type",
        content_name: "$content_name",
        content_filename: "$content_filename",
      }.freeze,
      count: { "$sum" => 1 }.freeze,
      db: { "$sum" => "$db" }.freeze,
      view: { "$sum" => "$view" }.freeze,
      elapsed: { "$sum" => "$elapsed" }.freeze,
      total_db: { "$sum" => "$total_db" }.freeze,
      total_view: { "$sum" => "$total_view" }.freeze,
      total_elapsed: { "$sum" => "$total_elapsed" }.freeze,
      sub_total_db: { "$sum" => "$sub_total_db" }.freeze,
      sub_total_view: { "$sum" => "$sub_total_view" }.freeze,
      sub_total_elapsed: { "$sum" => "$sub_total_elapsed" }.freeze
    }
  }.freeze

  AGGREGATE_HISTORIES_ADD_FIELDS_STAGE = {
    "$addFields" => {
      average_db: { "$divide" => [ "$db", "$count" ].freeze }.freeze,
      average_view: { "$divide" => [ "$view", "$count" ].freeze }.freeze,
      average_elapsed: { "$divide" => [ "$elapsed", "$count" ].freeze }.freeze,
      average_total_db: { "$divide" => [ "$total_db", "$count" ].freeze }.freeze,
      average_total_view: { "$divide" => [ "$total_view", "$count" ].freeze }.freeze,
      average_total_elapsed: { "$divide" => [ "$total_elapsed", "$count" ].freeze }.freeze,
      average_sub_total_db: { "$divide" => [ "$sub_total_db", "$count" ].freeze }.freeze,
      average_sub_total_view: { "$divide" => [ "$sub_total_view", "$count" ].freeze }.freeze,
      average_sub_total_elapsed: { "$divide" => [ "$sub_total_elapsed", "$count" ].freeze }.freeze
    }
  }.freeze

  def sub_total(history_ids)
    sub_total_db = 0
    sub_total_view = 0
    sub_total_elapsed = 0

    criteria = Cms::GenerationReport::History[title].all
    criteria = criteria.in(id: history_ids)
    criteria.pluck(:total_db, :total_view, :total_elapsed).each do |total_db, total_view, total_elapsed|
      sub_total_db += total_db if total_db
      sub_total_view += total_view if total_view
      sub_total_elapsed += total_elapsed if total_elapsed
    end

    [ sub_total_db, sub_total_view, sub_total_elapsed ]
  end
end
