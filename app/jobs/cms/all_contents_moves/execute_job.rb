class Cms::AllContentsMoves::ExecuteJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents_moves:execute"

  def perform(*args)
    check_task_id = args.first

    check_result = load_check_result(check_task_id)
    return unless check_result

    execute_data = load_execute_data(check_task_id)
    return unless execute_data

    selected_rows = filter_selected_rows(check_result, execute_data)
    return unless validate_user

    results = execute_moves(selected_rows)
    save_execute_result(results)
  end

  private

  def load_json_from_task(check_task_id, filename, validator: nil)
    check_task = Cms::Task.find(check_task_id)
  rescue Mongoid::Errors::DocumentNotFound, ActiveRecord::RecordNotFound => e
    task.log "Error: Check task #{check_task_id} not found"
    return nil
  else
    file_path = "#{check_task.base_dir}/#{filename}"
    unless File.exist?(file_path)
      task.log "Error: #{filename} not found"
      return nil
    end

    begin
      parsed_data = JSON.parse(File.read(file_path))
    rescue JSON::ParserError => e
      task.log "Error: Failed to parse #{filename}: #{e.message}"
      return nil
    end

    if validator && !validator.call(parsed_data)
      task.log "Error: #{filename} has invalid structure"
      return nil
    end

    parsed_data
  end

  def load_check_result(check_task_id)
    load_json_from_task(check_task_id, "check_result.json")
  end

  def load_execute_data(check_task_id)
    load_json_from_task(check_task_id, "execute_data.json")
  end

  def filter_selected_rows(check_result, execute_data)
    selected_ids = normalize_selected_ids(execute_data["selected_ids"])

    check_result["rows"].select do |row|
      row_id = row["id"]
      normalized_row_id = row_id.to_s.strip
      next false if normalized_row_id.blank? || !normalized_row_id.numeric?

      selected_ids.include?(normalized_row_id.to_i)
    end
  end

  def normalize_selected_ids(selected_ids_raw)
    Array(selected_ids_raw).filter_map do |id|
      normalized = id.to_s.strip
      next if normalized.blank? || !normalized.numeric?
      normalized.to_i
    end
  end

  def validate_user
    if user.blank?
      task.log I18n.t("cms.all_contents_moves.errors.user_not_bound")
      return false
    end
    true
  end

  def execute_moves(selected_rows)
    service = Cms::Page::MoveService.new(cur_site: site, cur_user: user, task: task)
    results = []

    task.total_count = selected_rows.size
    selected_rows.each do |row_data|
      task.count
      result = move_single_page(row_data, service)
      results << result
      log_move_result(result, row_data["destination_filename"])
    end

    results
  end

  def move_single_page(row_data, service)
    page_id = row_data["id"].to_i
    destination_filename = row_data["destination_filename"]

    task.log "Moving page #{page_id} to #{destination_filename}"

    page = Cms::Page.site(site).where(id: page_id).first
    if page.blank?
      return create_error_result(page_id, row_data["filename"], destination_filename)
    end

    result = service.move_page(page, destination_filename)
    normalize_move_result(result, page_id, row_data["filename"], destination_filename)
  end

  def create_error_result(page_id, filename, destination_filename)
    {
      success: false,
      errors: [I18n.t("cms.all_contents_moves.errors.page_not_found")],
      page_id: page_id,
      filename: filename,
      destination_filename: destination_filename
    }
  end

  def normalize_move_result(result, page_id, filename, destination_filename)
    # service.move_page が既に正しい構造を返しているが、
    # 将来の変更に備えて明示的に正規化する
    if result.is_a?(Hash) && result.key?(:success)
      # 既に正しい構造の場合は、不足しているメタデータを補完
      normalized = result.dup
      normalized[:page_id] ||= page_id
      normalized[:filename] ||= filename
      normalized[:destination_filename] ||= destination_filename
      normalized[:errors] = Array(normalized[:errors])
      normalized
    else
      # 予期しない形式の場合は、エラー結果として正規化
      {
        success: false,
        errors: result.is_a?(Hash) ? Array(result[:errors] || result[:error] || ["Unknown error"]) : ["Unexpected result format"],
        page_id: page_id,
        filename: filename,
        destination_filename: destination_filename
      }
    end
  end

  def log_move_result(result, destination_filename)
    if result[:success]
      task.log "  Success: moved to #{destination_filename}"
    else
      task.log "  Error: #{result[:errors].join(', ')}"
    end
  end

  def save_execute_result(results)
    execute_result = {
      task_id: task.id,
      results: results,
      created_at: Time.zone.now.iso8601,
      success_count: results.count { |r| r[:success] },
      error_count: results.count { |r| !r[:success] }
    }

    base = task.base_dir
    return unless base

    path = File.join(base, "execute_result.json")
    begin
      FileUtils.mkdir_p(base)
      File.write(path, execute_result.to_json)
    rescue => e
      task.log "Error: Failed to save execute_result.json: #{e.message}"
      task.log "  Path: #{path}"
      task.log "  Backtrace: #{e.backtrace.first(5).join("\n  ")}" if e.backtrace
    end

    task.log "Execute completed: #{execute_result[:success_count]} succeeded, #{execute_result[:error_count]} failed"
  end
end
