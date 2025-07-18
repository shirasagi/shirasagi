class Gws::Tabular::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::File

  navi_view "gws/tabular/main/navi"

  helper_method :cur_space, :forms, :find_views, :cur_form, :cur_release, :cur_view, :list_check_box?, :policy_class

  private

  def spaces
    @spaces ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.only(:id, :site_id, :i18n_name)
    end
  end

  def cur_space
    @cur_space ||= begin
      space = spaces.find(params[:space])
      space.site = space.cur_site = @cur_site
      space
    end
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria.only(:id, :site_id, :space_id, :i18n_name, :order, :revision, :updated)
      criteria.to_a
    end
  end

  def views
    @views ||= begin
      criteria = Gws::Tabular::View::Base.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.in(form_id: forms.map(&:id))
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria.only(:id, :site_id, :space_id, :form_id, :i18n_name, :order, :updated)
      criteria.to_a
    end
  end

  def find_views(form)
    views.select { |view| view.form_id == form.id }
  end

  def cur_form
    @cur_form ||= begin
      form_param = params[:form].to_s.presence
      form = forms.find { |form| form.id.to_s == form_param }
      raise "404" unless form
      form.site = form.cur_site = @cur_site
      form.space = form.cur_space = cur_space
      form
    end
  end

  def cur_release
    @cur_release ||= begin
      release = cur_form.current_release
      raise "404" unless release
      release
    end
  end

  def cur_view
    return @cur_view if instance_variable_defined?(:@cur_view)

    view_param = params[:view].to_s.presence
    if view_param == '-'
      @cur_view = Gws::Tabular::View::DefaultView.new(cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space)
    else
      @cur_view = views.find { |view| view.form_id == cur_form.id && view.id.to_s == view_param }
    end
    raise "404" unless @cur_view

    @cur_view.site = @cur_site
    @cur_view.space = cur_space
    @cur_view.form = cur_form
    @cur_view
  end

  def set_model
    @model = Gws::Tabular::File[cur_release]
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_tabular_label || t('modules.gws/tabular'), gws_tabular_spaces_path ]
    @crumbs << [ cur_space.i18n_name, gws_tabular_main_path ]
    @crumbs << [ cur_view.try(:i18n_name) || cur_form.i18n_name, url_for(action: :index) ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space, cur_form: cur_form }
  end

  def append_view_paths
    super

    cur_view.view_paths.each do |view_path|
      append_view_path view_path
    end
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def base_items
    @base_items ||= begin
      criteria = @model.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      order_hash = cur_view.order_hash
      if order_hash.present?
        criteria = criteria.reorder(order_hash)
      end

      criteria
    end
  end

  def index_items
    set_search_params
    base_items.search(@s)
  end

  def list_check_box?
    cur_view.owned?(@cur_user)
  end

  def policy_class
    Gws::Tabular::FilesPolicy
  end

  public

  def index
    raise "404" if cur_release.blank?
    raise "403" unless policy_class.index?(@cur_site, @cur_user, @model)

    @items = index_items.page(params[:page]).per(cur_view.try(:limit_count) || SS.max_items_per_page)
    render template: cur_view.index_template_path
  end

  def show
    raise "404" if cur_release.blank?
    raise "403" unless policy_class.show?(@cur_site, @cur_user, @model, @item)
    render
  end

  def new
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("edit")
    raise "403" unless policy_class.new?(@cur_site, @cur_user, @model)
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("edit")
    raise "403" unless policy_class.create?(@cur_site, @cur_user, @model)

    @item = @model.new get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if cur_form.workflow_enabled?
      @item.destination_group_ids = cur_form.destination_group_ids
      @item.destination_user_ids = cur_form.destination_user_ids
      if @item.destination_groups.active.present? || @item.destination_users.active.present?
        @item.destination_treat_state = "untreated"
      else
        @item.destination_treat_state = "no_need_to_treat"
      end
    end

    render_create @item.save
  end

  def edit
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("edit")
    raise "403" unless policy_class.edit?(@cur_site, @cur_user, @model, @item)

    if @item.is_a?(Cms::Addon::EditLock) && !@item.acquire_lock
      redirect_to action: :lock
      return
    end

    render
  end

  def update
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("edit")
    raise "403" unless policy_class.update?(@cur_site, @cur_user, @model, @item)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    if cur_form.workflow_enabled? && @item.destination_treat_state.blank?
      # 運用途中でワークフロー状態を有効にした場合、処理状態が未設定のためvalidation errorとなり保存できない。
      # そこで、処理状態が未設定の場合、提出先と処理状態とを設定する。
      @item.destination_group_ids = cur_form.destination_group_ids
      @item.destination_user_ids = cur_form.destination_user_ids
      if @item.destination_groups.active.present? || @item.destination_users.active.present?
        @item.destination_treat_state = "untreated"
      else
        @item.destination_treat_state = "no_need_to_treat"
      end
    end

    render_update @item.save
  end

  def delete
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("delete")
    raise "403" unless policy_class.delete?(@cur_site, @cur_user, @model, @item)

    render
  end

  def destroy
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("delete")
    raise "403" unless policy_class.destroy?(@cur_site, @cur_user, @model, @item)

    @item.record_timestamps = false
    @item.deleted = Time.zone.now
    render_destroy @item.save(context: :soft_delete)
  end

  def download_all
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("download_all")
    raise "403" unless policy_class.download_all?(@cur_site, @cur_user, @model)

    @item = SS::DownloadParam.new(cur_site: @cur_site, cur_user: @cur_user)
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.expect(item: [:encoding, :format])
    if @item.invalid?
      render
      return
    end

    set_model
    criteria = index_items

    case @item.format
    when 'zip'
      job = Gws::Tabular::File::ZipExportJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(cur_space.id.to_s, cur_form.id.to_s, cur_release.id.to_s, @item.encoding, criteria.pluck(:id).map(&:to_s))
      redirect_to(url_for(action: :index), notice: t('gws/tabular.notice.delay_download_with_message'))
    else # 'csv'
      exporter = Gws::Tabular::File::CsvExporter.new(
        site: @cur_site, user: @cur_user, space: cur_space, form: cur_form, release: cur_release, criteria: criteria)

      filename = "gws_tabular_files_#{cur_form.i18n_name}_#{Time.zone.now.to_i}.csv"
      send_enum exporter.enum_csv(encoding: @item.encoding), filename: filename
    end
  end

  def import
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("import")

    set_model
    raise "403" unless policy_class.import?(@cur_site, @cur_user, @model)

    @item = Gws::Tabular::File::ImportParam.new(cur_site: @cur_site, cur_user: @cur_user, cur_form: cur_form)
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.expect(item: [:in_file])
    if @item.invalid?
      render template: "import"
      return
    end

    extname = ::File.extname(@item.in_file.original_filename)
    extname = extname.downcase if extname
    case extname
    when ".csv"
      job_class = Gws::Tabular::File::CsvImportJob
      error_type = :malformed_csv
    when ".zip"
      job_class = Gws::Tabular::File::ZipImportJob
      error_type = :malformed_zip
    end

    if !job_class.valid_file?(@item.in_file)
      @item.errors.add :base, error_type
      render template: "import"
      return
    end

    temp_file = SS::TempFile.create_empty!(model: 'ss/temp_file', filename: @item.in_file.original_filename) do |new_file|
      IO.copy_stream(@item.in_file, new_file.path)
    end
    job = job_class.bind(site_id: @cur_site, user_id: @cur_user, group_id: @cur_group)
    job.perform_later(cur_space.id.to_s, cur_form.id.to_s, cur_release.id.to_s, temp_file.id)

    redirect_to url_for(action: :index), notice: t('ss.notice.started_import')
  end

  def copy
    raise "404" if cur_release.blank?
    raise "404" unless cur_view.authoring_allowed?("edit")
    raise "403" unless policy_class.copy?(@cur_site, @cur_user, @model)

    set_item

    service = Gws::Tabular::File::CopyService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, cur_form: cur_form, cur_release: cur_release, item: @item)

    if request.get? || request.head?
      @item = service.build
      render
      return
    end

    service.overwrites = params.require(:item).permit(*permit_fields)
    result = service.save

    render_opts = {}
    render_opts[:render] = { template: "copy" }
    if result
      render_opts[:notice] = t("ss.notice.copied")
      render_opts[:location] = url_for(action: :show, id: service.new_item)
    else
      @item = service.new_item
    end
    render_update result, render_opts
  end
end
