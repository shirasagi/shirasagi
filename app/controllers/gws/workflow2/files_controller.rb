class Gws::Workflow2::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow2::File

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_search_params
  before_action :set_items

  helper_method :destination_treat_state_options, :display_workflow_state

  navi_view "gws/workflow2/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow2_label || t("modules.gws/workflow2"), action: :index]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Workflow2::Form::Base.site(@cur_site)
      if params[:state] != 'preview'
        criteria = criteria.and_public
      end
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    return @cur_form if instance_variable_defined?(:@cur_form)
    if params[:form_id].blank? || params[:form_id] == 'default'
      @cur_form = nil
      return
    end

    set_forms
    @cur_form = @forms.find(params[:form_id])
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.state = params[:state].presence || 'all'
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      if params[:state] == "destination"
        s.destination_treat_state ||= "untreated"
      end
      s
    end
  end

  def set_items
    set_search_params
    @items ||= @model.site(@cur_site).without_deleted.search(@s)
  end

  def set_item
    set_items

    @item ||= begin
      item = @items.find(params[:id])
      # fix_params を呼び出す前に @cur_form をセットする必要がある
      @cur_form ||= item.form if item.present? && item.form_id.present?
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    if params[:action] == 'show' && params[:state] != "all"
      redirect_to gws_workflow2_file_path(state: "all")
      return
    end
    raise e
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site }
    params[:cur_form] = @cur_form if @cur_form
    params
  end

  def destination_treat_state_options
    @destination_treat_state_options ||= %w(untreated treated).map do |v|
      [ I18n.t("gws/workflow2.options.destination_treat_state.#{v}"), v ]
    end
    view_context.options_for_select(@destination_treat_state_options, selected: @s.destination_treat_state)
  end

  def display_workflow_state(item)
    state = item.workflow_state.presence || "draft"
    main = t("workflow.state.#{state}")

    if %w(approve approve_without_approval).include?(state) && item.destination_treat_state.present?
      treat_state = I18n.t("gws/workflow2.options.destination_treat_state.#{item.destination_treat_state}")
    end
    if treat_state
      main = "#{main} (#{treat_state})"
    end
    main
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
  end

  def show
    render
  end

  def new
    if params[:form_id].blank?
      form_select
      return
    end

    if @cur_form.is_a?(Gws::Workflow2::Form::External)
      url = @cur_form.url.presence
      if url
        redirect_to sns_redirect_path(ref: url)
        return
      end

      raise '404'
    end

    raise '403' unless @cur_form.readable?(@cur_user, site: @cur_site)

    @item = @model.new pre_params.merge(fix_params)
    render_opts = { template: "new" }
    render_opts[:layout] = false if request.xhr?
    render render_opts
  end

  def form_select
    set_forms
    @forms = @forms.search(params[:s]).page(params[:page]).per(50)
    render template: 'form_select'
  end

  def create
    raise "404" if @cur_form.blank? || !@cur_form.is_a?(Gws::Workflow2::Form::Application)
    raise '403' unless @cur_form.readable?(@cur_user, site: @cur_site)

    @item = @model.new get_params
    @item.name = @cur_form.new_file_name
    @item.destination_group_ids = @cur_form.destination_group_ids
    @item.destination_user_ids = @cur_form.destination_user_ids
    if @item.destination_groups.active.present? || @item.destination_users.active.present?
      @item.destination_treat_state = "untreated"
    else
      @item.destination_treat_state = "no_need_to_treat"
    end
    if params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end

    render_create @item.save
  end

  def edit
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    if @item.form_id.present? && @cur_form.blank?
      # form is deleted
      redirect_to url_for(action: :show), notice: I18n.t("gws/workflow2.notice.unable_to_edit_because_form_is_deleted")
      return
    end
    if @item.is_a?(Cms::Addon::EditLock) && !@item.acquire_lock
      redirect_to action: :lock
      return
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_update @item.save
  end

  def delete
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def soft_delete
    set_item unless @item
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    @item.record_timestamps = false
    @item.deleted = Time.zone.now
    @item.skip_validate_column_values = true
    render_destroy @item.save(context: :soft_delete)
  end

  def undo_delete
    set_item
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    @item.record_timestamps = false
    @item.deleted = nil

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { template: "undo_delete" }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.save, render_opts
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.destroyable?(@cur_user, site: @cur_site)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def request_cancel
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user)

    return if request.get? || request.head?

    @item.workflow_user_id = nil
    @item.workflow_state = nil
    @item.workflow_comment = nil
    @item.workflow_approvers = nil
    @item.workflow_required_counts = nil

    render_opts = { render: { template: "request_cancel" }, notice: t('workflow.notice.request_cancelled') }
    render_update @item.save, render_opts
  end

  def comment
    set_item
    render layout: false
  end

  def print
    set_item
    render layout: 'ss/print'
  end

  def copy
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user)
    if @item.form_id.present? && @cur_form.blank?
      # form is deleted
      redirect_to url_for(action: :show), notice: I18n.t("gws/workflow2.notice.unable_to_copy_because_form_is_deleted")
      return
    end

    if request.get? || request.head?
      return
    end

    service = Gws::Workflow2::CopyService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item)
    result = service.call

    render_opts = {}
    render_opts[:render] = { template: "copy" }
    if result
      render_opts[:notice] = I18n.t("gws/workflow2.notice.copy_created", name: service.new_item.name)
      render_opts[:location] = gws_workflow2_file_path(state: 'all', id: service.new_item)
    end
    render_update result, render_opts
  end

  def download_comment
    set_item

    filename = "workflow_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    encoding = "UTF-8"
    send_enum(@item.enum_csv(encoding: encoding), type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def approve_all
    set_selected_items

    service_class = Gws::Workflow2::ApproveService
    success = 0
    error = 0
    @items.each do |item|
      service = service_class.new(cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: item)
      valid = item.readable?(@cur_user, site: @cur_site)
      valid = item.workflow_state == "request" if valid == true
      valid = item.find_workflow_request_to(@cur_user).present? if valid == true
      valid = service.call if valid == true
      success += 1 if valid
      error +=1 unless valid
    end
    if success > 0
      notice = I18n.t('gws/workflow2.notice.count_approved', count: success)
    else
      notice = I18n.t('gws/workflow2.notice.not_approved')
    end
    render_update true, { location: { action: :index }, notice: notice }
  end

  def remand_all
    set_selected_items

    service_class = Gws::Workflow2::RemandService
    success = 0
    error = 0
    @items.each do |item|
      service = service_class.new(cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: item)
      valid = item.readable?(@cur_user, site: @cur_site)
      valid = item.workflow_state == "request" if valid == true
      valid = item.find_workflow_request_to(@cur_user).present? if valid == true
      valid = service.call if valid == true
      success += 1 if valid
      error +=1 unless valid
    end
    if success > 0
      notice = I18n.t('gws/workflow2.notice.count_remanded', count: success)
    else
      notice = I18n.t('gws/workflow2.notice.not_remanded')
    end
    render_update true, { location: { action: :index }, notice: notice }
  end

  def download_all_comments
    if params[:ids].blank?
      set_items
    else
      set_selected_items
    end

    filename = "workflow_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    encoding = "UTF-8"
    send_enum(@items.enum_csv(site: @cur_site, encoding: encoding), type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def download_attachment
    set_item

    files = @item.collect_attachments
    if files.blank?
      redirect_to({ action: :show }, { notice: t("gws/workflow.notice.no_files") })
      return
    end

    filename = "workflow_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    zip = Gws::Compressor.new(@cur_user, items: files, filename: filename)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename)

    if zip.deley_download?
      job = Gws::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :show }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save
      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end

  def download_all_attachments
    set_selected_items

    files = @items.collect_attachments
    if files.blank?
      redirect_to({ action: :index }, { notice: t("gws/workflow.notice.no_files") })
      return
    end

    filename = "workflow_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    zip = Gws::Compressor.new(@cur_user, items: files, filename: filename)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename)

    if zip.deley_download?
      job = Gws::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :index }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save
      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end
end
