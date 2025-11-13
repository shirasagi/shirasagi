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

  def load_check_result(check_task_id)
    check_task = Cms::Task.find(check_task_id)
    check_result_path = "#{check_task.base_dir}/check_result.json"
    unless File.exist?(check_result_path)
      task.log "Error: check_result.json not found"
      return nil
    end

    JSON.parse(File.read(check_result_path))
  end

  def load_execute_data(check_task_id)
    check_task = Cms::Task.find(check_task_id)
    execute_data_path = "#{check_task.base_dir}/execute_data.json"
    unless File.exist?(execute_data_path)
      task.log "Error: execute_data.json not found"
      return nil
    end

    JSON.parse(File.read(execute_data_path))
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

    service.move_page(page, destination_filename)
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

    FileUtils.mkdir_p(task.base_dir) if task.base_dir
    File.write("#{task.base_dir}/execute_result.json", execute_result.to_json) if task.base_dir

    task.log "Execute completed: #{execute_result[:success_count]} succeeded, #{execute_result[:error_count]} failed"
  end
end
