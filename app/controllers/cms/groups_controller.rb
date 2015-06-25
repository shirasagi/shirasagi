class Cms::GroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SearchableCrudFilter

  model Cms::Group

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.group", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

    def set_item
      super
      raise "403" unless Cms::Group.site(@cur_site).include?(@item)
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def role_edit
      set_item
      return "404" if @item.users.blank?
      render :role_edit
    end

    def role_update
      set_item
      role_ids = params[:item][:cms_role_ids].select(&:present?).map(&:to_i)

      @item.users.each do |user|
        user.set(cms_role_ids: role_ids)
      end
      render_update true
    end
end
