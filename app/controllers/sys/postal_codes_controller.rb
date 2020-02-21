class Sys::PostalCodesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::PostalCode
  menu_view "sys/crud/menu"

  private

  def set_crumbs
    @crumbs << [t("sys.postal_code"), action: :index]
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user)

    @items = @model.
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(prefecture_code: 1, code: 1, _id: 1).
      page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user)

    csv = @model.allow(:read, @cur_user).order(code: 1, id: 1).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "postal_code_#{Time.zone.now.to_i}.csv"
  end

  def import
    @item = SS::TempFile.new

    return if request.get?

    safe_params = params.require(:item).permit(:in_file, :in_official_csv)
    @item.in_file = safe_params[:in_file]

    if safe_params[:in_file].blank?
      @item.errors.add :in_file, :blank
      return
    end

    @item.save!

    if safe_params[:in_official_csv] == '1'
      job_class = Sys::PostalCode::OfficialCsvImportJob
    else
      job_class = Sys::PostalCode::ImportJob
    end
    job_class.bind(user_id: @cur_user).perform_later(@item.id)

    redirect_to({ action: :index }, { notice: I18n.t('ss.notice.started_import') })
  end
end
