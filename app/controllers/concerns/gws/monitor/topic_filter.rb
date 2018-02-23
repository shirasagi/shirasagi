module Gws::Monitor::TopicFilter
  extend ActiveSupport::Concern

  included do
    model Gws::Monitor::Topic

    before_action :set_item, only: %i[
      show edit update delete destroy public preparation question_not_applicable answered disable active publish
      close open download file_download
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
    if category_id = params[:category].presence
      if category_id != '-'
        @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
      end
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
    render file: "show_#{@item.mode}"
  end

  def destroy
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy, {notice: t('ss.notice.deleted')}
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

    render file: :new
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
    return if request.get?
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
    @download_file_group_ssfile_ids = []
    @item.attend_groups.each do |group|
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
end
