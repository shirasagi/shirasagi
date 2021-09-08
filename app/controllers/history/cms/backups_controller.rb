class History::Cms::BackupsController < ApplicationController
  include Cms::BaseFilter
  helper History::DiffHelper

  model History::Backup

  navi_view "cms/main/navi"

  before_action :set_item

  private

  def set_crumbs
    @crumbs << [t("history.backup"), action: :show]
  end

  def set_item
    @item = @model.where("data.site_id" => @cur_site.id).find(params[:id])
    raise "404" unless @data = @item.get
  end

  public

  def show
    render
  end

  def restore
    render
  end

  def update
    job_class = History::Backup::RestoreJob.bind(site_id: @cur_site, user_id: @cur_user)
    result = job_class.perform_now(@item.id.to_s)

    if result
      redirect_to({ action: :show }, { notice: I18n.t("history.notice.restored") })
    else
      render action: :restore
    end
  end

  def change
    render
  end
end
