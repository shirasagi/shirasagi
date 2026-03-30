class Cms::AllContents::MovesController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  HISTORY_ID_PATTERN = /\A[\w\-]+\z/

  before_action :check_permission
  before_action :set_task

  private

  def check_permission
    raise '403' unless @cur_user.cms_role_permit_any?(@cur_site, :use_cms_all_contents)
  end

  def set_crumbs
    @crumbs << [t("cms.all_contents"), cms_all_contents_path]
    @crumbs << [t("cms.all_content.moves_tab"), cms_all_contents_moves_path]
  end

  def set_task
    @task = Cms::Task.find_or_create_by(
      site_id: @cur_site.id,
      name: "cms:all_contents_moves"
    )
  end

  def validate_history_id!
    history_id = params[:id].to_s
    raise '404' unless history_id.match?(HISTORY_ID_PATTERN)

    history_dir = ::File.join(@task.base_dir, "histories", history_id)
    resolved = ::Pathname.new(history_dir).cleanpath.to_s
    allowed_base = ::Pathname.new(::File.join(@task.base_dir, "histories")).cleanpath.to_s
    raise '404' unless resolved.start_with?(allowed_base + "/")
    raise '404' unless ::Dir.exist?(resolved)

    resolved
  end

  def safe_json_parse(path, default: nil)
    return default unless ::File.exist?(path)

    JSON.parse(::File.read(path))
  rescue JSON::ParserError
    default
  end

  public

  def index
    @state = detect_state

    respond_to do |format|
      format.html do
        case @state
        when :initial
          load_histories
          render action: :index
        when :checking
          render action: :checking
        when :checked
          load_intermediate_results_with_pagination
          render action: :result
        when :moving
          render action: :moving
        when :completed
          load_move_results_with_pagination
          render action: :completed
        end
      end
      format.json do
        render json: { state: @state }
      end
    end
  end

  def template
    encoding = params[:encoding].presence || "UTF-8"
    exporter = Cms::AllContentsMoveExporter.new(site: @cur_site)
    enumerable = exporter.enum_csv(encoding: encoding)
    filename = "all_contents_moves_template_#{Time.zone.now.to_i}.csv"
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def import
    file = params.dig(:item, :in_file)
    if file.blank? || ::File.extname(file.original_filename).casecmp(".csv") != 0
      @errors = [t("errors.messages.invalid_csv")]
      load_histories
      return render(action: :index)
    end

    unless Cms::AllContentsMoveValidator.valid_csv?(file)
      @errors = [t("errors.messages.malformed_csv")]
      load_histories
      return render(action: :index)
    end

    unless @task.ready
      @errors = [t('ss.notice.already_job_started')]
      load_histories
      return render(action: :index)
    end

    # 前回の中間ファイルをクリーンアップ
    cleanup_intermediate_files

    temp_file = SS::TempFile.new
    temp_file.in_file = file
    temp_file.save!

    @csv_filename = file.original_filename

    job = Cms::AllContents::MoveCheckJob.bind(
      site_id: @cur_site, user_id: @cur_user
    )
    job.perform_later(temp_file.id)

    redirect_to({ action: :index, checking: 1 }, { notice: t('ss.notice.started_import') })
  end

  def result
    respond_to do |format|
      format.html { redirect_to action: :index }
      format.json { render json: load_all_intermediate_results }
    end
  end

  def run
    # ヘッダーチェックボックスで全選択された場合、全ページのエラー以外を対象にする
    if params[:select_all] == "1"
      all = load_all_intermediate_results
      selected_ids = all.reject { |r| r["status"] == "error" }.map { |r| r["id"] }
    else
      selected_ids = params[:ids]&.map(&:to_i) || []
    end

    if selected_ids.blank?
      @errors = [I18n.t('cms.all_contents_moves.errors.no_selection')]
      load_intermediate_results_with_pagination
      return render(template: "cms/all_contents/moves/result")
    end

    unless @task.ready
      @errors = [t('ss.notice.already_job_started')]
      load_intermediate_results_with_pagination
      return render(template: "cms/all_contents/moves/result")
    end

    job = Cms::AllContents::MoveExecuteJob.bind(
      site_id: @cur_site, user_id: @cur_user
    )
    job.perform_later(selected_ids)

    redirect_to({ action: :index, moving: 1 }, { notice: t('ss.notice.started_move') })
  end

  def reset
    cleanup_intermediate_files
    redirect_to({ action: :index }, { notice: t('ss.notice.deleted') })
  end

  def download_logs
    if @task.log_file_path && ::File.exist?(@task.log_file_path)
      send_file @task.log_file_path, type: "text/plain", filename: "move_logs_#{Time.zone.now.to_i}.log",
        disposition: :attachment
    else
      head :not_found
    end
  end

  def download_result
    raise '404' unless move_result_file_exists?

    encoding = params[:encoding].presence || "UTF-8"
    results = safe_json_parse(move_result_file_path, default: [])
    send_result_csv(results, encoding: encoding, filename: "move_result_#{Time.zone.now.to_i}.csv")
  end

  def show_history
    history_dir = validate_history_id!

    meta_path = ::File.join(history_dir, "meta.json")
    result_path = ::File.join(history_dir, "move_result.json")

    @history_meta = safe_json_parse(meta_path, default: {})
    @history_results = safe_json_parse(result_path, default: [])

    respond_to do |format|
      format.html { render action: :show_history }
      format.json { render json: @history_results }
    end
  end

  def download_history
    history_dir = validate_history_id!

    result_path = ::File.join(history_dir, "move_result.json")
    results = safe_json_parse(result_path, default: [])

    encoding = params[:encoding].presence || "UTF-8"
    send_result_csv(results, encoding: encoding, filename: "move_result_#{params[:id]}.csv")
  end

  private

  def detect_state
    # import/run直後のリダイレクトでは、ジョブが高速完了していても実行中画面を表示する
    return :checking if params[:checking].present?
    return :moving if params[:moving].present?

    @task.reload
    if @task.running?
      return move_result_file_exists? ? :moving : :checking
    end
    return :completed if move_result_file_exists?
    return :checked if intermediate_check_file_exists?
    :initial
  end

  def intermediate_dir
    @task.base_dir
  end

  def intermediate_check_file_path
    ::File.join(intermediate_dir, "check_result.json")
  end

  def move_result_file_path
    ::File.join(intermediate_dir, "move_result.json")
  end

  def intermediate_check_file_exists?
    ::File.exist?(intermediate_check_file_path)
  end

  def move_result_file_exists?
    ::File.exist?(move_result_file_path)
  end

  def load_all_intermediate_results
    return [] unless intermediate_check_file_exists?

    @all_results ||= JSON.parse(::File.read(intermediate_check_file_path))
  end

  def load_intermediate_results_with_pagination
    all = load_all_intermediate_results
    @summary = {
      total: all.size,
      ok: all.count { |r| r["status"] == "ok" },
      confirmation: all.count { |r| r["status"] == "confirmation" },
      error: all.count { |r| r["status"] == "error" }
    }
    @results = Kaminari.paginate_array(all).page(params[:page]).per(50)
  end

  def load_move_results_with_pagination
    return unless move_result_file_exists?

    all = JSON.parse(::File.read(move_result_file_path))
    @move_summary = {
      total: all.size,
      ok: all.count { |r| r["status"] == "ok" },
      error: all.count { |r| r["status"] == "error" }
    }
    @move_results = Kaminari.paginate_array(all).page(params[:page]).per(50)
  end

  def load_histories
    history_dir = ::File.join(@task.base_dir, "histories")
    @histories = []
    return unless ::Dir.exist?(history_dir)

    ::Dir.children(history_dir).sort.reverse_each do |entry|
      entry_path = ::File.join(history_dir, entry)
      next unless ::File.directory?(entry_path)

      meta_path = ::File.join(entry_path, "meta.json")
      next unless ::File.exist?(meta_path)

      meta = safe_json_parse(meta_path, default: nil)
      next unless meta

      meta["dir_name"] = entry
      @histories << meta
    end
  end

  def cleanup_intermediate_files
    FileUtils.rm_f(intermediate_check_file_path)
    FileUtils.rm_f(move_result_file_path)
  end

  def send_result_csv(results, encoding:, filename:)
    type_labels = { "page" => "ページ", "layout" => "レイアウト", "part" => "パーツ", "node" => "フォルダー" }

    rows = []
    rows << %w[行 ページID 移動先ファイル名 ステータス エラー 参照元コンテンツ]
    results.each do |r|
      confirmations_text = ""
      if r["confirmations"].present?
        confirmations_text = r["confirmations"].map do |c|
          "#{type_labels[c['type']] || c['type']}: #{c['name']} (#{c['filename']})"
        end.join("\n")
      end

      rows << [
        r["row"], r["id"], r["filename"], r["status"],
        r["errors"]&.join("; "),
        confirmations_text
      ]
    end

    if encoding.casecmp("Shift_JIS") == 0
      csv_data = CSV.generate { |csv| rows.each { |row| csv << row } }
      csv_data = csv_data.encode("Shift_JIS", invalid: :replace, undef: :replace, replace: "?")
      content_type = "text/csv; charset=Shift_JIS"
    else
      csv_data = "\uFEFF" + CSV.generate { |csv| rows.each { |row| csv << row } }
      content_type = "text/csv; charset=UTF-8"
    end

    send_data csv_data, type: content_type, filename: filename, disposition: :attachment
  end

end
