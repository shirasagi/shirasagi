class Gws::RemindersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Reminder

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/reminder", action: :index]
    end

  public
    def index
      @items = @model.site(@cur_site).
        user(@cur_user).
        search(params[:s]).
        page(params[:page]).per(50)
    end
end
