class Contact::SearchGroupsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Group

  def index
    return index_in_group if SS.current_user_group

    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def index_in_group
    @items = @model.site(@cur_site).
      in_group(SS.current_user_group).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
