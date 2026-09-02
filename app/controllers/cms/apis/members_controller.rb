class Cms::Apis::MembersController < ApplicationController
  include Cms::ApiFilter

  model Cms::Member

  def index
    @single = params[:single].present?
    @multi = !@single

    set_items
    @items = @items.
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
