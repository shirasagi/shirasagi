class Gws::Memo::NoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model SS::Notification

  def fix_params
    { cur_user: @cur_user, cur_group: @cur_site }
  end

  private

  def set_item
    super
    raise "404" unless @item.readable?(@cur_user, group: @cur_site)
  end

  public

  def index
    @items = @model.member(@cur_user).
      undeleted(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def delete
    render
  end

  def destroy
    render_destroy @item.destroy_from_member(@cur_user)
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if @cur_user.id == item.user_id || item.member?(@cur_user)
        next if item.destroy_from_member(@cur_user)
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_confirmed_all(entries.size != @items.size)
  end

  def recent
    @items = @model.member(@cur_user).
      undeleted(@cur_user).
      search(params[:s]).
      limit(5)

    render :recent, layout: false
  end

  def show
    @item.set_seen(@cur_user).update if @item.state == "public"

    if @item.url.present?
      redirect_to @item.url
      return
    end

    if @item.text.present? || @item.html.present?
      render
      return
    end

    redirect_to request.referer, notice: I18n.t("ss.notice.set_seen")
  end

  def latest
    @unseen = @model.member(@cur_user).
      undeleted(@cur_user).
      unseen(@cur_user)

    if params[:filter] == 'unseen'
      @items = @unseen
    else
      @items = @model.member(@cur_user).
        undeleted(@cur_user).
        limit(10)
    end

    resp = {
      latest: @unseen.first.try(:created),
      unseen: @unseen.size,
      items: @items.map do |item|
        {
          date: item.created,
          subject: item.subject,
          url: gws_memo_notice_url(id: item.id),
          unseen: item.unseen?(@cur_user)
        }
      end
    }
    render json: resp.to_json
  end

  def set_seen_all
    ids = params[:ids]
    if ids
      ids = ids.map(&:to_i) rescue nil
    end

    @items = SS::Notification.unseens(@cur_user).to_a
    @items = @items.select { |item| ids.include?(item.id) } if ids
    @items.each do |item|
      item.set_seen(@cur_user).update
    end

    flash[:notice] = I18n.t("ss.notice.set_seen")
    respond_to do |format|
      format.html { redirect_to(action: :index) }
      format.json { head :no_content }
    end
  end
end
