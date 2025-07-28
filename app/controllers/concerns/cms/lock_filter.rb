module Cms::LockFilter
  extend ActiveSupport::Concern

  included do
    # テスト時 unlock 実行前に database cleaner が実行されてしまい、
    # unlock → edit へリダイレクト → unlock  → edit へリダイレクトと無限ループにハマってしまう。
    # それを防ぐために、logged_in? でログイン判定をせずに自前で判定するようにする。
    skip_before_action :logged_in?, only: [:unlock]
  end

  def lock
    set_item rescue nil
    if @item.blank?
      head :no_content
      return
    end

    if !@item.respond_to?(:acquire_lock)
      head :unprocessable_entity
      return
    end

    if @item.acquire_lock(force: params[:force].present?)
      render
    else
      respond_to do |format|
        format.html { render }
        format.json { render json: [ t("errors.messages.locked", user: @item.lock_owner.try(:long_name)) ], status: :locked }
      end
    end
  end

  def unlock
    login_by_oauth2_token || login_by_session
    unless @cur_user
      head :unauthorized
      return
    end

    set_item rescue nil
    if @item.blank?
      head :no_content
      return
    end

    if !@item.respond_to?(:release_lock)
      head :unprocessable_entity
      return
    end

    unless @item.locked?
      respond_to do |format|
        format.html { redirect_to(action: :edit) }
        format.json { head :no_content }
      end
      return
    end

    raise "403" if !@item.lock_owned? && !@item.allowed?(:unlock, @cur_user, site: @cur_site, node: @cur_node)

    unless @item.locked?
      respond_to do |format|
        format.html { redirect_to(action: :edit) }
        format.json { head :no_content }
      end
      return
    end

    if @item.release_lock(force: params[:force].present?)
      respond_to do |format|
        format.html { redirect_to(action: :edit) }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render template: "show" }
        format.json { render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked }
      end
    end
  end
end
