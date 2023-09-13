module Gws::Monitor::TopicFilter
  extend ActiveSupport::Concern
  include Gws::Memo::NotificationFilter

  included do
    model Gws::Monitor::Topic

    before_action :set_item, only: %i[
      show edit update delete destroy public preparation question_not_applicable answered disable active publish
      close open download file_download all_topic_files print
    ]

    before_action :set_selected_items, only: %i[
      destroy_all public_all preparation_all question_not_applicable_all disable_all active_all
    ]

    before_action :set_category
  end

  private

  # override Gws::CrudFilter#append_view_paths
  def append_view_paths
    append_view_path "app/views/gws/monitor/main"
    super
  end

  def set_category
    @categories = Gws::Monitor::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort
    if (category_id = params[:category].presence) && category_id != '-'
      @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    ret = { due_date: Time.zone.today + 7 }
    if @category.present?
      ret[:category_ids] = [ @category.id ]
    end
    ret[:notice_state] = @cur_site.default_notice_state.presence || '3_days_before_due_date'
    ret
  end

  public

  def index
    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    set_items
  end

  def show
    raise "403" unless @item.attended?(@cur_group) || @item.allowed?(:read, @cur_user, site: @cur_site)

    render template: "show_#{@item.mode}"
  end

  def destroy
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    render_destroy @item.destroy
  end

  FORWARD_ATTRIBUTES = %w(name spec_config due_date notice_state notice_start_at mode text_type text category_ids).freeze

  # 転送する
  def forward
    raise '403' unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    set_item
    @source = @item
    @item = @model.new(@source.attributes.slice(*FORWARD_ATTRIBUTES).merge(fix_params))
    @item.group_ids = [@cur_group.id]
    @item.user_ids = [@cur_user.id]
    @item.ref_file_ids = @source.file_ids

    render template: "new"
  end

  def copy
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      @item.name = "[#{I18n.t("workflow.cloned_name_prefix")}] #{@item.name}".truncate(80)
      return
    end

    @new_item = @item.new_clone
    result = @new_item.save
    if !result
      SS::Model.copy_errors(@new_item, @item)
    end

    render_opts = {}
    render_opts[:render] = { template: "copy" }
    if result
      render_opts[:location] = gws_monitor_admin_path(id: @new_item)
    end
    render_update result, render_opts
  end

  # 受け取り済みにする
  def public
    @item.attributes = fix_params
    raise '403' unless @item.attended?(@cur_group)

    @item.answer_state_hash.update(@cur_group.id.to_s => "public")
    @item.save
    render_update @item.update
  end

  # 受取待ちにする
  def preparation
    @item.attributes = fix_params
    raise '403' unless @item.attended?(@cur_group)

    @item.answer_state_hash.update(@cur_group.id.to_s => "preparation")
    @item.save
    render_update @item.update
  end

  # 該当なしにする
  def question_not_applicable
    @item.attributes = fix_params
    raise '403' unless @item.attended?(@cur_group)

    @item.answer_state_hash.update(@cur_group.id.to_s => "question_not_applicable")
    @item.save
    render_update @item.update
  end

  # 公開する
  def publish
    @item.attributes = fix_params
    @item.state = 'public'
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    return if request.get? || request.head?

    @item.attributes = get_params
    render_update @item.save, {notice: t('gws/monitor.notice.published')}
  end

  # 募集締切
  def close
    @item.attributes = fix_params
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_update @item.update(state: 'closed'), {notice: t('gws/monitor.notice.close')}
  end

  # 再募集
  def open
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_update @item.update(state: 'public'), {notice: t('gws/monitor.notice.open')}
  end

  # 回答一覧CSV
  def download
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    csv = @item.to_csv.encode('SJIS', invalid: :replace, undef: :replace)
    send_data csv, filename: "monitor_#{Time.zone.now.to_i}.csv"
  end

  # 添付ファイル一括ダウンロード
  def file_download
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    component = Gws::Monitor::TopicZipCreator.new(cur_site: @cur_site, cur_user: @cur_user, cur_group: @cur_group, topic: @item)
    if component.create_zip
      filename = SS::FilenameUtils.convert_to_url_safe_japanese("#{@item.name}.zip")
      send_file component.zip_path, type: 'application/zip', filename: filename,
               disposition: 'attachment', x_sendfile: true
    else
      redirect_to url_for(action: :show), notice: component.errors.full_messages.join("\n")
    end
  end

  # ファイル一括ダンロード（トピック）
  def all_topic_files
    zip_creator = SS::ZipCreator.new("gws_monitor_topic_files.zip", @cur_user, cur_site: @cur_site)
    @item.files.each do |file|
      zip_creator.add_file(file)
    end
    zip_creator.close

    filename = "gws_monitor_topic_files_#{Time.zone.now.to_i}.zip"
    send_file(zip_creator.path, type: 'application/zip', filename: filename, disposition: 'attachment', x_sendfile: true)
  ensure
    zip_creator.close if zip_creator.present?
  end

  # 全て受け取りにする
  def public_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.attended?(@cur_group)
        item.answer_state_hash.update(@cur_group.id.to_s => "public")
        next if item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(@items.blank?, notice: t("gws/monitor.notice.public"))
  end

  # 全ての受け取りを元に戻す
  def preparation_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.attended?(@cur_group)
        item.answer_state_hash.update(@cur_group.id.to_s => "preparation")
        next if item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(@items.blank?, notice: t("gws/monitor.notice.preparation"))
  end

  # すべてを該当なしにする
  def question_not_applicable_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.attended?(@cur_group)
        item.answer_state_hash.update(@cur_group.id.to_s => "question_not_applicable")
        next if item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end

    render_destroy_all(@items.blank?, notice: t("gws/monitor.notice.question_not_applicable"))
  end

  # # すべての削除を取り消す
  # def undo_delete_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:delete, @cur_user, site: @cur_site)
  #       next if item.active
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(@items.blank?, notice: t("gws/monitor.notice.active"))
  # end

  def print
    raise "403" unless @item.attended?(@cur_group) || @item.allowed?(:read, @cur_user, site: @cur_site)

    render template: "print_#{@item.mode}", layout: 'ss/print'
  end
end
