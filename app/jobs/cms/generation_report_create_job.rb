# frozen_string_literal: true

class Cms::GenerationReportCreateJob < Cms::ApplicationJob
  def perform(*args)
    if !::File.exist?(generation_task.perf_log_file_path) || ::File.size(generation_task.perf_log_file_path).zero?
      Rails.logger.info { "#{generation_task.perf_log_file_path} is not found" }
      return
    end

    Rails.logger.tagged(::File.basename(generation_task.perf_log_file_path)) do
      reader.each_line do |line|
        line.strip!
        performance_info = JSON.parse(line)
        import_performance_info(performance_info)
      end

      aggregate_histories
    rescue => e
      Rails.logger.error { e.to_s }
      raise
    end
  ensure
    if @reader
      @reader.close rescue nil
      @reader = nil
    end
    if @tmp_file
      @tmp_file.close rescue nil
      ::FileUtils.rm_f(@tmp_file.path) rescue nil
      @tmp_file = nil
    end
  end

  private

  def generation_task
    @generation_task ||= Cms::Task.all.site(site).find(arguments[0])
  end

  def generation_type
    @generation_type ||= begin
      case generation_task.name
      when "cms:generate_pages"
        :pages
      when "cms:generate_nodes"
        :nodes
      end
    end
  end

  def tmp_file
    @tmp_file ||= begin
      tmp = ::Tempfile.create("json", "#{Rails.root}/tmp")
      Retriable.retriable { ::FileUtils.cp(generation_task.perf_log_file_path, tmp.path) }
      tmp
    end
  end

  def reader
    @reader ||= begin
      reader = Zlib::GzipReader.open(tmp_file.path)
      @header_line = reader.readline
      reader
    end
  end

  def digest
    Cms::GenerationReport.sha256_hash(tmp_file.path)
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
    reader

    if @header_line
      header = JSON.parse(@header_line)
      if header["type"] == "header"
        title_name = header["name"]
      end
    end
    unless title_name
      title_name = generation_task.started ? "performance log at #{generation_task.started.iso8601}" : "performance log"
      case generation_type
      when :pages
        title_name = "generate page #{title_name}".strip
      when :nodes
        title_name = "generate node #{title_name}".strip
      end
    end

    title = Cms::GenerationReport::Title.new(
      cur_site: site, name: title_name,
      task: generation_task, task_started: generation_task.started, task_closed: generation_task.closed,
      sha256_hash: digest, generation_type: generation_type)
    title.save!
    title
  end

  def import_performance_info(performance_info)
    content = find_content(performance_info)
    return unless content

    history = Cms::GenerationReport::History[title].new(
      cur_site: site, site: site, task: generation_task, title: title, history_type: performance_info["type"],
      content: content, content_name: performance_info["name"], content_filename: performance_info["filename"],
      db: performance_info["db"], view: performance_info["view"], elapsed: performance_info["elapsed"],
      total_db: performance_info["db"], total_view: performance_info["view"], total_elapsed: performance_info["elapsed"])
    history.page_no = performance_info["page"] if performance_info["page"]
    history.save!

    pending_histories = pending_relation.delete(relation_key(performance_info))
    if pending_histories.present?
      build_relations!(history, performance_info, pending_histories)
    end

    scope = performance_info["scopes"].try(:last)
    if scope.present?
      scope = relation_key(scope)
      pending_relation[scope] ||= []
      pending_relation[scope] << history
    end
  end

  def relation_key(performance_info)
    # performance_info.slice("type", "id", "page")
    %w(type id page).map { |key| performance_info[key] }.join(":")
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

  def build_relations!(history, _performance_info, pending_histories)
    pending_histories.each do |pending_history|
      pending_history.update(parent: history)
    end

    history.child_ids = pending_histories.map(&:id)
    sub_total_db, sub_total_view, sub_total_elapsed = sub_total(history.child_ids)

    history.sub_total_db = sub_total_db
    history.sub_total_view = sub_total_view
    history.sub_total_elapsed = sub_total_elapsed
    if sub_total_db && sub_total_db > 0
      history.db ||= 0
      history.db -= sub_total_db
    end
    if sub_total_view && sub_total_view > 0
      history.view ||= 0
      history.view -= sub_total_view
    end
    if sub_total_elapsed && sub_total_elapsed > 0
      history.elapsed ||= 0
      history.elapsed -= sub_total_elapsed
    end
    history.save!
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
        cur_site: site, site: site, task: generation_task, title: title, history_type: result["_id"]["history_type"],
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
