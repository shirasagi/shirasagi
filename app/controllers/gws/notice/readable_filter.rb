module Gws::Notice::ReadableFilter
  extend ActiveSupport::Concern

  included do
    before_action :check_permission
    before_action :set_folders
    before_action :set_folder
    before_action :set_categories
    before_action :set_category
    before_action :set_groups
    before_action :set_group
    before_action :set_search_params
    before_action :set_items
  end

  private

  def check_permission
    raise "404" unless Gws::Notice.allowed?(:use, @cur_user, site: @cur_site)
  end

  def set_folders
    @folders ||= Gws::Notice::Folder.for_post_reader(@cur_site, @cur_user)
  end

  def set_folder
    return if params[:folder_id].blank? || params[:folder_id] == '-'
    @folder = @folders.find(params[:folder_id])
  end

  def set_categories
    @categories ||= Gws::Notice::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    return if params[:category_id].blank? || params[:category_id] == '-'
    @category ||= @categories.find(params[:category_id])
    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_groups
    @groups ||= Gws::Group.active.site(@cur_site)
  end

  def set_group
    return if params[:group_id].blank? || params[:group_id] == '-'
    @group ||= @groups.where(id: @s[:group_id]).first
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
    @s[:site] = @cur_site
    @s[:user] = @cur_user
    if @folder.present?
      @s[:folder_ids] = [ @folder.id ]
      @s[:folder_ids] += @folder.folders.for_post_reader(@cur_site, @cur_user).pluck(:id)
    end
    @s[:category_id] = @category.id if @category.present?
    @s[:group_id] = @group.id if @group.present?
    @s[:browsed_state] = @cur_site.notice_browsed_state if @s[:browsed_state].nil?
    @s[:severity] = @cur_site.notice_severity if @s[:severity].nil?
  end

  def set_items
    @items = @model.site(@cur_site).and_public.
      readable(@cur_user, site: @cur_site).
      without_deleted
  end

  def set_item
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.search(@s).reorder(released: -1, id: -1).page(params[:page]).per(50)
  end

  def show
    if @cur_site.notice_toggle_by_read? && params[:toggled].blank? && !@item.browsed?(@cur_user)
      @item.set_browsed!(@cur_user)
      @item.reload
    end
    render
  end

  def toggle_browsed
    if @item.browsed?(@cur_user)
      @item.unset_browsed!(@cur_user)
    else
      @item.set_browsed!(@cur_user)
    end

    render_update true, location: { action: :show, toggled: 1 }
  rescue => e
    render_update false, render: { template: :show, toggled: 1 }
  end

  def set_browsed_all
    @items = @items.in(id: params[:ids])
    @items.each do |item|
      item.set_browsed!(@cur_user) unless item.browsed?(@cur_user)
    end
    redirect_to({ action: :index }, notice: t("ss.notice.set_seen_all"))
  end

  def unset_browsed_all
    @items = @items.in(id: params[:ids])
    @items.each do |item|
      item.unset_browsed!(@cur_user) if item.browsed?(@cur_user)
    end
    redirect_to({ action: :index }, notice: t("ss.notice.unset_seen_all"))
  end

  def print
    render template: "print", layout: 'ss/print'
  end

  def download_attachment
    set_item

    files = @item.files
    if files.blank?
      redirect_to({ action: :show }, { notice: t("gws/workflow.notice.no_files") })
      return
    end

    filename = "notice_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    name = "#{@item.name}.zip"
    zip = Gws::Compressor.new(@cur_user, model: SS::File, items: files, filename: filename, name: name)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename, name: name)

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
end
