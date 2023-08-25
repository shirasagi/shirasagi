class Cms::GroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Group

  navi_view "cms/main/group_navi"

  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def set_crumbs
    @crumbs << [t("cms.group"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  def set_item
    @item = @model.unscoped.site(@cur_site).find params[:id]
    @item.attributes = fix_params
    raise "403" unless @model.unscoped.site(@cur_site).include?(@item)
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def reload_nginx
    if SS.config.ss.updates_and_reloads_nginx_conf
      SS::Nginx::Config.new.write.reload_server
    end
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence if @search_params

    @items = @model.unscoped.site(@cur_site).
      state(params.dig(:s, :state)).
      allow(:read, @cur_user, site: @cur_site)

    if @search_params
      @items = @items.search(@search_params).
        order_by(name: 1, order: 1, id: 1)
    else
      @items = @items.tree_sort
    end
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end

  def role_edit
    set_item
    return "404" if @item.users.blank?
    render :role_edit
  end

  def role_update
    set_item
    role_ids = params[:item][:cms_role_ids].select(&:present?).map(&:to_i)

    @item.users.each do |user|
      set_ids = user.cms_role_ids - Cms::Role.site(@cur_site).map(&:id) + role_ids
      user.set(cms_role_ids: set_ids)
    end
    render_update true
  end

  def download_all
    return if request.get? || request.head?

    @item = SS::DownloadParam.new
    @item.attributes = params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    exporter = Cms::GroupExporter.new(site: @cur_site, criteria: @model.unscoped.site(@cur_site).order_by(_id: 1))
    send_enum exporter.enum_csv(encoding: @item.encoding), filename: "cms_groups_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get? || request.head?

    @item = SS::ImportParam.new(cur_site: @cur_site, cur_user: @cur_user)
    @item.attributes = params.require(:item).permit(:in_file)
    if @item.in_file.blank? || ::File.extname(@item.in_file.original_filename).casecmp(".csv") != 0
      @item.errors.add :base, :invalid_csv
      render action: :import
      return
    end

    if !Cms::GroupImportJob.valid_csv?(@item.in_file)
      @item.errors.add :base, :malformed_csv
      render action: :import
      return
    end

    temp_file = SS::TempFile.create_empty!(model: 'ss/temp_file', filename: @item.in_file.original_filename) do |new_file|
      IO.copy_stream(@item.in_file, new_file.path)
    end
    job = Cms::GroupImportJob.bind(site_id: @cur_site, user_id: @cur_user)
    job.perform_later(temp_file.id)
    redirect_to url_for(action: :index), notice: t('ss.notice.started_import')
  end
end
