class Webmail::GroupsController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Group

  append_view_path "app/views/sys/groups"

  before_action :set_contact_email, only: [:show, :edit]
  before_action :set_default_settings, only: [:edit, :update]
  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.webmail/group'), action: :index]
  end

  def reload_nginx
    if SS.config.ss.updates_and_reloads_nginx_conf
      SS::Nginx::Config.new.write.reload_server
    end
  end

  def set_contact_email
    @contact_email = @item.contact_email
  end

  def set_default_settings
    label = t('webmail.default_settings')
    conf = @cur_user.imap_default_settings

    @item.default_imap_setting = {
      from: @cur_user.name,
      address: @contact_email.presence || conf[:address],
      host: "#{label} / #{conf[:host]}",
      auth_type: "#{label} / #{conf[:auth_type]}",
      account: "#{label} / #{conf[:account]}",
      password: "#{label} / #{conf[:password].to_s.gsub(/./, '*')}"
    }
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user)

    @items = @model.allow(:edit, @cur_user).
      state(params.dig(:s, :state)).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def new
    super
    set_default_settings
  end

  def create
    @item = @model.new get_params
    set_default_settings
    render_create @item.save
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user)

    # @item = @model.new
    return if request.get? || request.head?

    # @item = Webmail::GroupExport.new params.require(:item).permit(Webmail::GroupExport.permitted_fields)
    # @item.cur_user = @cur_user
    # result = @item.import_csv
    # flash.now[:notice] = t("ss.notice.saved") if result
    # render_create result, location: { action: :import }, render: { template: "import" }
    @item = SS::ImportParam.new(cur_site: @cur_site, cur_user: @cur_user)
    @item.attributes = params.require(:item).permit(:in_file)
    if @item.in_file.blank? || ::File.extname(@item.in_file.original_filename).casecmp(".csv") != 0
      @item.errors.add :base, :invalid_csv
      render action: :import
      return
    end

    if !Webmail::GroupImportJob.valid_csv?(@item.in_file)
      @item.errors.add :base, :malformed_csv
      render action: :import
      return
    end

    temp_file = SS::TempFile.create_empty!(model: 'ss/temp_file', filename: @item.in_file.original_filename) do |new_file|
      IO.copy_stream(@item.in_file, new_file.path)
    end
    job = Webmail::GroupImportJob.bind(site_id: @cur_site, user_id: @cur_user)
    job.perform_later(temp_file.id)
    redirect_to url_for(action: :index), notice: t('ss.notice.started_import')
  end

  def download_all
    raise "403" unless @model.allowed?(:edit, @cur_user)
    return if request.get? || request.head?

    @item = SS::DownloadParam.new
    @item.attributes = params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    items = @model.all.allow(:edit, @cur_user).reorder(id: 1)
    exporter = Webmail::GroupExporter.new(criteria: items)
    send_enum exporter.enum_csv(encoding: @item.encoding), filename: "webmail_groups_#{Time.zone.now.to_i}.csv"
  end

  def download_template
    raise "403" unless @model.allowed?(:edit, @cur_user)

    items = @model.all.allow(:edit, @cur_user).reorder(id: 1)
    exporter = Webmail::GroupExporter.new(criteria: items, template: true)
    send_enum exporter.enum_csv(encoding: "UTF-8"), filename: "webmail_groups_#{Time.zone.now.to_i}.csv"
  end
end
