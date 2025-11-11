class Cms::AllContentsMoves::ExecuteJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents_moves:execute"

  def perform(*args)
    check_task_id = args.first

    # チェックジョブのタスクから中間生成物を読み込む
    check_task = Cms::Task.find(check_task_id)
    check_result_path = "#{check_task.base_dir}/check_result.json"
    unless File.exist?(check_result_path)
      task.log "Error: check_result.json not found"
      return
    end

    check_result = JSON.parse(File.read(check_result_path))

    # 実行データを読み込む
    execute_data_path = "#{check_task.base_dir}/execute_data.json"
    unless File.exist?(execute_data_path)
      task.log "Error: execute_data.json not found"
      return
    end

    execute_data = JSON.parse(File.read(execute_data_path))
    selected_ids = Array(execute_data["selected_ids"]).filter_map do |id|
      normalized = id.to_s.strip
      next if normalized.blank? || !normalized.numeric?
      normalized.to_i
    end

    # 選択された行をフィルタリング（ページIDは整数で比較）
    selected_rows = check_result["rows"].select do |row|
      row_id = row["id"]
      normalized_row_id = row_id.to_s.strip
      next false if normalized_row_id.blank? || !normalized_row_id.numeric?

      selected_ids.include?(normalized_row_id.to_i)
    end

    if user.blank?
      task.log I18n.t("cms.all_contents_moves.errors.user_not_bound")
      return
    end

    service = Cms::Page::MoveService.new(cur_site: site, cur_user: user, task: task)
    results = []

    task.total_count = selected_rows.size
    selected_rows.each do |row_data|
      task.count
      page_id = row_data["id"].to_i
      destination_filename = row_data["destination_filename"]

      task.log "Moving page #{page_id} to #{destination_filename}"

      page = Cms::Page.site(site).where(id: page_id).first
      if page.blank?
        result = {
          success: false,
          errors: [I18n.t("cms.all_contents_moves.errors.page_not_found")],
          page_id: page_id,
          filename: row_data["filename"],
          destination_filename: destination_filename
        }
        results << result
        task.log "  Error: Page not found"
        next
      end

      result = service.move_page(page, destination_filename)
      results << result

      if result[:success]
        task.log "  Success: moved to #{destination_filename}"
      else
        task.log "  Error: #{result[:errors].join(', ')}"
      end
    end

    # 実行結果を保存
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
