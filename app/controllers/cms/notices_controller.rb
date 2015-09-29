class Cms::NoticesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SearchableCrudFilter

  model Cms::Notice

  navi_view "cms/main/conf_navi"

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :copy]

  private
    def set_crumbs
      @crumbs << [:"cms.notice", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        allow(:edit, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def copy
      raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      if request.get?
        prefix = I18n.t("workflow.cloned_name_prefix")
        @item.name = "[#{prefix}] #{@item.name}"
        return
      end

      @item.attributes = get_params
      @copy = @item.new_clone
      render_update @copy.save, location: { action: :index }, render: { file: :copy }
    end
end
