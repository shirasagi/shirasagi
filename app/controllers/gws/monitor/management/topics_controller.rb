class Gws::Monitor::Management::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic

  before_action :set_item, only: [
      :show, :edit, :update, :delete, :destroy,
      :close, :open, :download, :file_download
  ]

  before_action :set_category

  private

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [t("mongoid.models.gws/monitor/management"), gws_monitor_management_topics_path]
      @crumbs << [@category.name, action: :index]
    else
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [t("mongoid.models.gws/monitor/management"), gws_monitor_management_topics_path]
    end
  end

  def set_category
    @categories = Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    current_category_id = super
    if @category.present?
      current_category_id[:category_ids] = [ @category.id ]
    end
    current_category_id
  end

  public

  def index
    @items = @model.site(@cur_site).topic

    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    @items = @items.search(params[:s]).
        custom_order(params.dig(:s, :sort) || 'updated_desc').
        page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render file: "/gws/monitor/management/main/show_#{@item.mode}"
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    diff_attend_group_readable_group = (@item.attend_group_ids - @item.readable_group_ids).uniq
    if diff_attend_group_readable_group.present?
      @item.attributes["readable_group_ids"] = @item.attributes["readable_group_ids"] + diff_attend_group_readable_group
    end

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def close
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(article_state: 'closed'), {notice: t('gws/monitor.notice.close')}
  end

  def open
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(article_state: 'open'), {notice: t('gws/monitor.notice.open')}
  end

  def download
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    csv = @item.to_csv.
        encode('SJIS', invalid: :replace, undef: :replace)

    send_data csv, filename: "monitor_#{Time.zone.now.to_i}.csv"
  end

  def file_download
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    @download_file_group_ssfile_ids = []
    @item.subscribed_groups.each do |group|
      if @item.comment(group.id).present?
        download_file_ids = @item.comment(group.id)[0]
        @download_file_group_ssfile_ids << [File.basename(download_file_ids.user_group_name), download_file_ids.file_ids]
      end
    end

    download_file_group_ssfile_ids_hash = @download_file_group_ssfile_ids.to_h
    @group_ssfile = []
    download_file_group_ssfile_ids_hash.each do |group_fileids|
      group_fileids[1].each do |fileids|
        @group_ssfile.push([group_fileids[0], SS::File.find_by(id: fileids)])
      end
    end

    download_root_dir = "/tmp/shirasagi_download"
    download_dir = download_root_dir + "/" + "#{@cur_user.id}_#{SecureRandom.hex(4)}"

    Dir.glob(download_root_dir + "/" + "#{@cur_user.id}_*").each do |tmp_dir|
      FileUtils.rm_rf(tmp_dir) if File.exists?(tmp_dir)
    end

    FileUtils.mkdir_p(download_dir) unless FileTest.exist?(download_dir)

    @group_ssfile.each do |groupssfile|
      if File.exist?(groupssfile[1].path)
        FileUtils.copy(groupssfile[1].path, download_dir + "/" + groupssfile[0] + "_" + groupssfile[1].name)
      end
    end

    @zipfile = download_dir + "/" + Time.zone.now.strftime("%Y-%m-%d_%H-%M-%S") + ".zip"
    Zip::File.open(@zipfile, Zip::File::CREATE) do |zip_file|
      Dir.glob("#{download_dir}/*").each do |downloadfile|
        zip_file.add(NKF::nkf('-sx --cp932', File.basename(downloadfile)), downloadfile)
      end
    end
    send_file(@zipfile, type: 'application/zip', filename: File.basename(@zipfile), disposition: 'attachment')

    @item.delete_temporary_files(@zipfile, self.response_body)

  end
end
