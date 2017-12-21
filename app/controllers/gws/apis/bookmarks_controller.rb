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
      url: params.dig(:bookmark, :url)
    ).first
  end

  public

  def create
    item = find_item || @model.new(params.require(:bookmark).permit(permit_fields).merge(fix_params))
    if params.dig(:bookmark, :name).present?
      item.name = params.dig(:bookmark, :name)
    else
      item.name = params.dig(:bookmark, :default_name)
    end
    item.bookmark_model = 'other' unless @model::BOOKMARK_MODEL_TYPES.include?(params.dig(:bookmark, :bookmark_model))

    render_create item.save, location: params.dig(:bookmark, :url)
  end

  def destroy
    item = find_item

    render_destroy item.destroy, location: params.dig(:bookmark, :url)
  end
end
