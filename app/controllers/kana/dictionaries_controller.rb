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
      @item = @model.site(@cur_site).find(params[:id])
      raise "403" unless @item
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site) || @model.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def build
      raise "403" unless @model.allowed?(:build, @cur_user, site: @cur_site)

      put_history_log
      begin
        error_message = @model.build_dic @cur_site.id
        unless error_message
          redirect_to({ action: :index }, { notice: t("kana.build_success") })
          return
        end

        # this is user's invalid operation.
        @errors = [ error_message ]
        render :status => :bad_request
      rescue
        # occuring exception means system error.
        logger.error $ERROR_INFO
        logger.error $ERROR_INFO.backtrace.join("\n")
        @errors = [ $ERROR_INFO.to_s ]
        render :status => :internal_server_error
      end
    end
end
