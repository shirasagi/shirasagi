class Gws::Memo::NoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Notice

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  private

  def set_item
    super
    raise "404" unless @item.readable?(@cur_user, @cur_site)
  end

  public

  def index
    @items = @model.site(@cur_site).
      member(@cur_user).
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
    render_destroy_all(entries.size != @items.size)
  end

  def recent
    @items = @model.site(@cur_site).
      member(@cur_user).
      undeleted(@cur_user).
      search(params[:s]).
      limit(5)

    render :recent, layout: false
  end

  def show
    @item.set_seen(@cur_user).update if @item.state == "public"
  end

  def latest
    from = params[:from].present? ? Time.zone.parse(params[:from]) : Time.zone.now - 12.hours

    @unseen = @model.site(@cur_site).
      member(@cur_user).
      undeleted(@cur_user).
      unseen(@cur_user)

    @items = @model.site(@cur_site).
      member(@cur_user).
      undeleted(@cur_user).
      limit(10).
      entries

    resp = {
      recent: @unseen.where(:created.gte => from).size,
      unseen: @unseen.size,
      latest: @items.first.try(:created),
      items: @items.map do |item|
        {
          date: item.created,
          subject: item.subject,
          url: gws_memo_notice_url(id: item.id)
        }
      end
    }
    render json: resp.to_json
  end
end
