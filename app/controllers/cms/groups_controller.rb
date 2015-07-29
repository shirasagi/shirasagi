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
        search(params[:s]).sort_by(&:name)
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
        set_ids = user.cms_role_ids - Cms::Role.site(@cur_site).map(&:id) + role_ids
        user.set(cms_role_ids: set_ids)
      end
      render_update true
    end

    def download
      csv = @model.site(@cur_site).order_by(_id: 1).to_csv
      send_data csv.encode("SJIS"), filename: "cms_groups_#{Time.zone.now.to_i}.csv"
    end

    def import
      return if request.get?
      @item = @model.new get_params
      @item.cur_site = @cur_site
      result = @item.import
      flash.now[:notice] = t("views.notice.saved") if !result && @item.imported > 0
      render_create result, location: { action: :index }, render: { file: :import }
    end
end
