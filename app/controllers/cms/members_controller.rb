class Cms::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Member

  navi_view "cms/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"cms.member", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        allow(:edit, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(name: 1, id: 1).
        page(params[:page]).per(50)
    end

    def download
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

      csv = @model.site(@cur_site).
        allow(:edit, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(id: 1).
        to_csv
      send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "members_#{Time.zone.now.to_i}.csv"
    end
end
