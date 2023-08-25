class History::Cms::BackupsController < ApplicationController
  include Cms::BaseFilter

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

  def set_task
    task_name = "#{@item.ref_coll}:#{@item.data["_id"]}"
    @task ||= SS::Task.order_by(id: 1).find_or_create_by(site_id: @cur_site.id, name: task_name)
  end

  public

  def show
    render
  end

  def restore
    render
  end

  def update
    set_task
    if !@task.ready
      @item.errors.add :base, :other_task_is_running
      render action: :restore
      return
    end

    job_class = History::Backup::RestoreJob.bind(site_id: @cur_site, user_id: @cur_user)
    result = job_class.perform_now(@item.id.to_s)

    if result
      redirect_to({ action: :show }, { notice: I18n.t("history.notice.restored") })
    else
      render action: :restore
    end
  rescue Job::SizeLimitPerUserExceededError => _e
    @item.errors.add :base, :other_task_is_running
    render action: :restore
  end

  def change
    render
  end
end
