class Gws::Monitor::Management::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic
  navi_view "gws/monitor/management/navi"

  before_action :set_item, only: [
    :show, :edit, :update, :delete, :destroy,
    :close, :open, :download, :file_download,
    :public, :preparation, :question_not_applicable, :answered, :disable
  ]

  before_action :set_selected_items, only: [
    :destroy_all, :public_all,
    :preparation_all, :question_not_applicable_all, :disable_all
  ]

  before_action :set_category

  private

  def set_crumbs
    set_category
    @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
    if @category.present?
      @crumbs << [@category.name, gws_monitor_topics_path]
    end
    @crumbs << [t('ss.management'), gws_monitor_management_main_path]
    @crumbs << [t('gws/monitor.tabs.article_management'), action: :index]
  end

  def set_category
    @categories = Gws::Monitor::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    ret = super
    if @category.present?
      ret[:category_ids] = [ @category.id ]
    end
    ret
  end

  def render_destroy_all(result)
    location = crud_redirect_url || { action: :index }
    notice = result ? { notice: t("gws/monitor.notice.disable") } : {}
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end

  public

  def index
    @items = @model.site(@cur_site).topic

    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    if @cur_user.gws_role_permissions["read_other_gws_monitor_posts_#{@cur_site.id}"]
      @items = @items.search(params[:s]).
          custom_order(params.dig(:s, :sort) || 'updated_desc').
          page(params[:page]).per(50)
    else
      @items = @items.search(params[:s]).
          and_admins(@cur_user).
          custom_order(params.dig(:s, :sort) || 'updated_desc').
          page(params[:page]).per(50)
    end
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render file: "/gws/monitor/management/main/show_#{@item.mode}"
  end

  def create
    @item = @model.new get_params

    @item.attributes["readable_group_ids"] = (@item.attend_group_ids + @item.readable_group_ids).uniq

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
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

  def public
    raise '403' unless @item.readable?(@cur_user, site: @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "public")
    @item.save
    render_update @item.update
  end

  def preparation
    raise '403' unless @item.readable?(@cur_user, site: @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "preparation")
    @item.save
    render_update @item.update
  end

  def question_not_applicable
    raise '403' unless @item.readable?(@cur_user, site: @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "question_not_applicable")
    @item.save
    render_update @item.update
  end

  def answered
    raise '403' unless @item.readable?(@cur_user, site: @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "answered")
    @item.save
    render_update @item.update
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable, {notice: t('gws/monitor.notice.disable')}
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

    @owner_ssfile = []
    @item.file_ids.each do |fileids|
      @owner_ssfile.push([ File.basename(@cur_group.name), SS::File.find_by(id: fileids)])
    end

    zipfile = @item.name + ".zip"

    @item.create_download_directory(File.dirname(@item.zip_path))
    @item.create_zip(@item.zip_path, @group_ssfile, @owner_ssfile)
    send_file(@item.zip_path, type: 'application/zip', filename: zipfile, disposition: 'attachment', x_sendfile: true)
  end

  def public_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, site: @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "public")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def preparation_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, site: @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "preparation")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def question_not_applicable_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, site: @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "question_not_applicable")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
