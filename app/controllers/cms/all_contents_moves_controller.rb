class Cms::AllContentsMovesController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  before_action :check_permission
  before_action :set_task, only: [:index, :execute, :reset]

  private

  def check_permission
    raise '403' unless @cur_user.cms_role_permit_any?(@cur_site, :use_cms_all_contents)
  end

  def set_crumbs
    @crumbs << [t("cms.all_contents"), cms_all_contents_path]
    @crumbs << [t("cms.all_content.moves_tab"), cms_all_contents_moves_path]
  end

  def set_task
    job_class = Cms::AllContentsMoves::CheckJob
    @task = job_class.task_class.find_or_create_by(site_id: @cur_site.id, name: job_class.task_name)
  end

  def load_check_result
    return nil unless @task.base_dir
    result_path = "#{@task.base_dir}/check_result.json"
    return nil unless File.exist?(result_path)

    JSON.parse(File.read(result_path))
  rescue => e
    Rails.logger.error("Failed to load check result: #{e.message}")
    nil
  end

  def load_execute_result
    execute_job_class = Cms::AllContentsMoves::ExecuteJob
    execute_task = execute_job_class.task_class.find_by(site_id: @cur_site.id, name: execute_job_class.task_name)
    return nil unless execute_task&.base_dir
    
    result_path = "#{execute_task.base_dir}/execute_result.json"
    return nil unless File.exist?(result_path)

    JSON.parse(File.read(result_path))
  rescue => e
    Rails.logger.error("Failed to load execute result: #{e.message}")
    nil
  end

  public

  def index
    if request.get? || request.head?
      @check_result = load_check_result
      @execute_result = load_execute_result
      if @execute_result
        execute_job_class = Cms::AllContentsMoves::ExecuteJob
        @execute_task = execute_job_class.task_class.find_by(site_id: @cur_site.id, name: execute_job_class.task_name)
      end
      render
      return
    end

    # POST: CSVアップロード
    safe_params = params.require(:item).permit(:in_file)
    file = safe_params[:in_file]
    if file.blank? || ::File.extname(file.original_filename).casecmp(".csv") != 0
      @errors = [t("errors.messages.invalid_csv")]
      render
      return
    end

    if !Cms::AllContentsMoves::CheckJob.valid_csv?(file)
      @errors = [t("errors.messages.malformed_csv")]
      render
      return
    end

    if !@task.ready
      @errors = [t('ss.notice.already_job_started')]
      render
      return
    end

    temp_file = SS::TempFile.new
    temp_file.in_file = file
    temp_file.save!

    job = Cms::AllContentsMoves::CheckJob.bind(site_id: @cur_site, user_id: @cur_user)
    job.perform_later(temp_file.id)
    redirect_to({ action: :index }, { notice: t('ss.notice.started_import') })
  end

  def template
    enumerable = enum_csv_template(encoding: "Shift_JIS")

    filename = "all_contents_moves_template_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def execute
    check_result = load_check_result
    if check_result.blank?
      @errors = [t("cms.all_contents_moves.errors.check_result_not_found")]
      render action: :index
      return
    end

    selected_ids = params[:selected_ids] || []
    if selected_ids.blank?
      @errors = [t("cms.all_contents_moves.errors.no_selection")]
      @check_result = check_result
      render action: :index
      return
    end

    # 選択された行をフィルタリング
    selected_rows = check_result["rows"].select { |row| selected_ids.include?(row["id"].to_s) }
    if selected_rows.blank?
      @errors = [t("cms.all_contents_moves.errors.invalid_selection")]
      @check_result = check_result
      render action: :index
      return
    end

    # 中間生成物を保存
    execute_data = {
      task_id: @task.id,
      selected_ids: selected_ids.map(&:to_s),
      created_at: Time.zone.now.iso8601
    }
    FileUtils.mkdir_p(@task.base_dir) if @task.base_dir
    File.write("#{@task.base_dir}/execute_data.json", execute_data.to_json) if @task.base_dir

    # 実行ジョブ用のタスクを作成
    execute_job_class = Cms::AllContentsMoves::ExecuteJob
    execute_task = execute_job_class.task_class.find_or_create_by(site_id: @cur_site.id, name: execute_job_class.task_name)

    if !execute_task.ready
      @errors = [t('ss.notice.already_job_started')]
      @check_result = check_result
      render action: :index
      return
    end

    job = Cms::AllContentsMoves::ExecuteJob.bind(site_id: @cur_site, user_id: @cur_user)
    job.perform_later(@task.id)
    redirect_to({ action: :index }, { notice: t('ss.notice.started_import') })
  end

  def reset
    clear_task_files(@task, %w[check_result.json execute_data.json])

    execute_job_class = Cms::AllContentsMoves::ExecuteJob
    execute_task = execute_job_class.task_class.find_by(site_id: @cur_site.id, name: execute_job_class.task_name)
    clear_task_files(execute_task, %w[execute_result.json])

    redirect_to({ action: :index }, { notice: t('cms.all_contents_moves.reset_notice') })
  end

  private

  def enum_csv_template(options = {})
    encoding = options[:encoding] || "Shift_JIS"
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_basic(drawer)
      draw_meta(drawer)
      draw_contact(drawer)
      draw_groups(drawer)
    end

    drawer.enum(template_criteria, options.merge(model: Cms::Page, encoding: encoding))
  end

  def template_criteria
    Cms::Page.site(@cur_site).all
  end

  def draw_basic(drawer)
    drawer.column :page_id do
      drawer.head { I18n.t("all_content.page_id") }
      drawer.body { |item| item.id }
    end
    drawer.column :name
    drawer.column :filename do
      drawer.head { I18n.t("mongoid.attributes.cms/model/page.filename") }
      drawer.body { |item| item.filename }
    end
    drawer.column :index_name
    drawer.column :layout do
      drawer.head { I18n.t("mongoid.attributes.cms/reference/layout.layout") }
      drawer.body { |item| item.layout.try(:name) }
    end
    drawer.column :order
  end

  def draw_meta(drawer)
    drawer.column :keywords
    drawer.column :description
    drawer.column :summary_html
  end

  def draw_contact(drawer)
    drawer.column :contact_state, type: :label
    drawer.column :contact_group do
      drawer.head { I18n.t("mongoid.attributes.cms/addon/contact/group.contact_group") }
      drawer.body { |item| item.contact_group.try(:name) }
    end
    drawer.column :contact_charge
    drawer.column :contact_tel
    drawer.column :contact_fax
    drawer.column :contact_email
    drawer.column :contact_postal_code
    drawer.column :contact_address
    drawer.column :contact_link_url
    drawer.column :contact_link_name
  end

  def draw_groups(drawer)
    drawer.column :groups do
      drawer.head { I18n.t("mongoid.attributes.cms/addon/group_permission.groups") }
      drawer.body { |item| item.groups.pluck(:name).join("\n") }
    end
  end

  def clear_task_files(task, filenames)
    return if task.blank?
    base_dir = task.base_dir
    return if base_dir.blank?

    filenames.each do |filename|
      path = File.join(base_dir, filename)
      FileUtils.rm_f(path)
    end
  end
end
