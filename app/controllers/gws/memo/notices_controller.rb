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
end
