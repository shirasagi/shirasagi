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

    if params[:s] && params[:s][:state] == "closed"
      @items = @items.and_closed.allow(:read, @cur_user, site: @cur_site)
    else
      @items = @items.and_public.readable(@cur_user, @cur_site)
    end

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

  def close
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(article_state: 'closed')
  end

  def open
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(article_state: 'open')
  end

  def download
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    csv = @item.to_csv.
        encode('SJIS', invalid: :replace, undef: :replace)

    send_data csv, filename: "monitor_#{Time.zone.now.to_i}.csv"
  end

  def file_download
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @download_file_groups = []
    @item.subscribed_groups.each do |group|
      @download_file_groups << @item.comment(group.id)[0].file_ids if @item.comment(group.id).present?
    end

    download_file_ids = @download_file_groups.flatten
    download_file_ids.uniq!

    @download_files = []
    download_file_ids.each do |id|
      @download_files.push(SS::File.find_by(id: id))
    end

    @download_files.each do |download_file|
      puts "hoge"
      # download_file : #<SS::File _id: 7, created: 2017-10-21 14:47:13 UTC, updated: 2017-10-21 14:47:17 UTC, text_index: nil, user_id: 2, geo_location: nil, model: "gws/monitor/post", state: "public", name: "UAQ57L1N-01.fdf", filename: "UAQ57L1N-01.fdf", size: 213969, content_type: "application/vnd.fdf", site_id: 8>
      # download_file.path : "/Users/ftakao2007/rubymine/shirasagi_jsd_monitor/private/files/ss_files/7/_/7"
      # download_file..content_type : "application/vnd.fdf"
      # @download_file.filename : "UAQ57L1N-01.fdf"
      # @download_file.name : "UAQ57L1N-01.fdf"   ### 日本語のファイルもちゃんと表示される方
    end

    # download_dir_path = '/tmp/jorurimail_download' + '/' + Core.user.id.to_s + '_' + SecureRandom.hex(4)
    # zipfile = download_dir_path + '/' + Time.now.strftime("%Y-%m-%d_%H-%M-%S") + '_' + uids.size.to_s + '.zip'
    #
    # Zip::File.open(zipfile, Zip::File::CREATE) do |zip_file|
    #   Dir.glob("#{download_dir_path}/*").each do |mailfile|
    #     zip_file.add(NKF::nkf('-sx --cp932',File.basename(mailfile)), mailfile)
    #   end
    # end
    #
    # send_file(zipfile, type: 'application/zip', filename: File.basename(zipfile), disposition: 'attachment')



    # id = params[:id_path].present? ? params[:id_path].gsub(/\//, "") : params[:id]
    # path = params[:filename]
    # path << ".#{params[:format]}" if params[:format].present?
    #
    # @item = SS::File.find_by id: id, filename: path
    #
    # ### @item は 自分の記事のidだけ入っている
    # zip = @item.to_zip(download_file_ids)
    #
    # puts zip
    #
    # if Fs.mode == :file && Fs.file?(@item.path)
    #   send_file @item.path, type: @item.content_type, filename: @item.filename,
    #             disposition: :inline, x_sendfile: true
    # else
    #   send_data @item.read, type: @item.content_type, filename: @item.filename,
    #             disposition: :inline
    # end


  end
end
