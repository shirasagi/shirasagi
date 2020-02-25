class Gws::UserTitlesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::UserTitle

  navi_view "gws/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.ss/user_title"), gws_user_titles_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      state(params.dig(:s, :state)).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def download_all
    @item = SS::DownloadParam.new
    if request.get?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:encoding).merge(fix_params)
    if @item.invalid?
      render
      return
    end

    criteria = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
    enumerable = criteria.enum_csv(cur_site: @cur_site, encoding: @item.encoding)
    filename = "gws_user_titles_#{Time.zone.now.to_i}.csv"
    send_enum(enumerable, type: "text/csv; charset=#{@item.encoding}", filename: filename)
  end

  def import
    @item = SS::ImportParam.new
    if request.get?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:in_file).merge(fix_params)
    if @item.invalid?
      render
      return
    end

    unless Gws::UserTitleImportJob.valid_csv?(@item.in_file)
      @item.errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
      render
      return
    end

    # save csv to use in job
    ss_file = SS::TempFile.new
    ss_file.in_file = @item.in_file
    ss_file.save

    # call job
    Gws::UserTitleImportJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later(ss_file.id)
    redirect_to({ action: :index }, { notice: I18n.t("ss.notice.started_import") })
  end
end
