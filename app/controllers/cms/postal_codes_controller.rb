class Cms::PostalCodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::PostalCode

  navi_view "cms/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"cms.postal_code", action: :index]
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.
        allow(:edit, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(prefecture_code: 1, code: 1, _id: 1).
        page(params[:page]).per(50)
    end

    def download
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      csv = @model.allow(:read, @cur_user, site: @cur_site).order(code: 1, id: 1).to_csv
      send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "postal_code_#{Time.zone.now.to_i}.csv"
    end

    def import
      return if request.get?

      safe_params = params.require(:item).permit(:in_file, :in_official_csv)

      temp_file = SS::TempFile.new
      temp_file.in_file = safe_params[:in_file]
      temp_file.save!

      if safe_params[:in_official_csv] == '1'
        job_class = Cms::PostalCode::OfficialCsvImportJob
      else
        job_class = Cms::PostalCode::ImportJob
      end
      job_class.bind(site_id: @cur_site, user_id: @cur_user).perform_later(temp_file.id)

      redirect_to({ action: :index }, { notice: I18n.t('cms.messages.import') })
    end
end
