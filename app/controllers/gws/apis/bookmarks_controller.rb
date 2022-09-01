class Gws::Apis::BookmarksController < ApplicationController
  include Gws::ApiFilter
  include Gws::CrudFilter

  model Gws::Bookmark

  skip_before_action :set_item

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def find_item
    @model.where(
      site_id: @cur_site.id,
      user_id: @cur_user.id,
      url: params.dig(:item, :url).to_s
    ).first
  end

  public

  def create
    @item = @model.new(get_params)
    return render_create(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true)

    @item.bookmark_model = @model.detect_model(params.dig(:item, :model).to_s, @item.url)
    @item.save
    render json: { bookmark_id: @item.id, notice: I18n.t('gws/bookmark.notice.save') }
  end

  def update
    @item = find_item
    @item.attributes = get_params

    return render_update(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    @item.update
    render json: { bookmark_id: @item.id, notice: I18n.t('gws/bookmark.notice.save') }
  end

  def destroy
    @item = find_item
    if @item.blank?
      head :ok
      return
    end

    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    @item.destroy
    head :ok
  end
end
