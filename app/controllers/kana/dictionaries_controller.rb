class Kana::DictionariesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Kana::Dictionary

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"kana.dictionary", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

    def set_item
      @item = @model.where(site_id: @cur_site.id).find(params[:id])
      raise "403" unless @item
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site) || @model.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def build
      raise "403" unless @model.allowed?(:build, @cur_user, site: @cur_site)

      put_history_log
      begin
        @model.build_dic @cur_site.id
        notice = t("kana.build_success")
      rescue
        notice = $!.to_s
        logger.error $!.to_s
        logger.error $!.backtrace.join("\n")
      end

      redirect_to({ action: :index }, { notice: notice })
    end
end
