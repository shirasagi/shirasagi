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
      url: params.dig(:item, :url)
    ).first
  end

  public

  def create
    item = find_item || @model.new(get_params)
    if params.dig(:item, :name).present?
      item.name = params.dig(:item, :name)
    else
      item.name = params.dig(:item, :default_name)
    end
    model = params.dig(:item, :model).sub(/gws\/(?<model>[^\/]*)\/?.*/) do
      Regexp.last_match[:model]
    end
    if @model::BOOKMARK_MODEL_TYPES.include?(model)
      item.bookmark_model = model
    else
      item.bookmark_model = 'other'
    end

    item.save
    render json: { name: item.name, bookmark_id: item.id }
  end

  def destroy
    item = find_item

    item.try(:destroy)
    render nothing: true
  end
end
