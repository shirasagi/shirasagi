module Cms::LockFilter
  extend ActiveSupport::Concern

  def lock
    set_item rescue nil
    if @item.blank?
      head :no_content
      return
    end

    if @item.acquire_lock(force: params[:force].present?)
      render
    else
      respond_to do |format|
        format.html { render }
        format.json { render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked }
      end
    end
  end

  def unlock
    set_item rescue nil
    if @item.blank?
      head :no_content
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
        format.html { render file: :show }
        format.json { render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked }
      end
    end
  end
end
