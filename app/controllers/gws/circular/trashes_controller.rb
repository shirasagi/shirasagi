class Gws::Circular::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Circular::PostFilter

  before_action :set_item, only: [:show, :delete, :destroy, :active, :recover]
  before_action :set_selected_items, only: [:active_all, :destroy_all]
  before_action :set_category

  private

  def set_items
    @items ||= @model.site(@cur_site).
      topic.
      only_deleted.
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
