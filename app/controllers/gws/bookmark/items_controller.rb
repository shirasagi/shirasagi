class Gws::Bookmark::ItemsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Bookmark::BaseFilter

  model Gws::Bookmark::Item

  before_action :set_selected_items, only: [:move_all]
  before_action :set_tree_navi, only: [:index]
  before_action :set_destination_folders, only: [:index]

  navi_view "gws/bookmark/main/navi"

  private

  def pre_params
    { bookmark_model: Gws::Bookmark::BOOKMARK_MODEL_DEFAULT_TYPE, folder: (@folder || @root_folder) }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_bookmark_label || t("mongoid.models.gws/bookmark/item"), action: :index]
    @crumbs << [t("ss.navi.readable"), action: :index]
  end

  def set_item
    super
    raise "404" unless @item.user_id == @cur_user.id
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_tree_navi
    @tree_navi = gws_bookmark_apis_folder_list_path(folder_id: params[:folder_id], format: 'json')
  end

  # 一括移動・ドラッグ&ドロップの移動先候補（ログインユーザーが所有する全フォルダー）。
  def set_destination_folders
    @destination_folders = @folders.
      allow(:read, @cur_user, site: @cur_site).
      tree_sort
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).user(@cur_user)
    @items = @items.and_folder(@folder) if @folder
    @items = @items.search(params[:s]).
      page(params[:page]).per(50)
  end

  def move_all
    # 移動先フォルダー。ルートのパススコープ :folder_id（現在のフォルダー）と衝突するため、
    # 移動先は dst_folder_id で受け取る。
    folder = @folders.where(id: params[:dst_folder_id]).first
    raise "404" if folder.blank?
    raise "403" unless folder.allowed?(:read, @cur_user, site: @cur_site)

    # 再描画時に再クエリされてエラー情報が失われないよう、配列として保持する
    @items = @items.to_a
    moved = []
    @items.each do |item|
      unless item.user_id == @cur_user.id && item.allowed?(:edit, @cur_user, site: @cur_site)
        item.errors.add :base, :auth_error
        next
      end

      next if item.folder_id == folder.id

      item.folder_id = folder.id
      next unless item.save

      moved << item
    end

    render_change_all(moved: moved, location: { action: :index, folder_id: params[:folder_id] })
  end

  def render_change_all(opts = {})
    location = opts[:location].presence || crud_redirect_url || { action: :index }
    failed = @items.select { |item| item.errors.present? }

    notice =
      if failed.present?
        # 権限エラーで弾いた項目がある場合は、細工された ids[] による他ユーザーの
        # ブックマーク名の漏洩を防ぐため、名前を含めない汎用メッセージにフォールバックする。
        if failed.any? { |item| item.errors.details[:base].any? { |detail| detail[:error] == :auth_error } }
          t("errors.messages.auth_error")
        else
          t("gws/bookmark.notice.move_failed", names: failed.map(&:name).join("、"))
        end
      elsif opts[:moved].blank?
        # 全件が移動先と同一フォルダーにあった等、実際には何も移動しなかった場合
        t("gws/bookmark.notice.move_none")
      else
        t("ss.notice.saved")
      end

    # 一括移動はフォーム送信（HTML）のみで呼ばれるため、リダイレクトで応答する
    redirect_to location, notice: notice
  end
end
