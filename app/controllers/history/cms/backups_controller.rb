class History::Cms::BackupsController < ApplicationController
  include Cms::BaseFilter

  model History::Backup

  navi_view "cms/main/navi"

  before_action :set_item, :check_compare_to

  helper_method :item, :ref_item, :compare_to_item

  private

  def set_crumbs
    @crumbs << [t("history.backup"), action: :show]
  end

  def set_item
    @item ||= @model.where("data.site_id" => @cur_site.id).find(params[:id])
  end
  alias item set_item

  def set_task
    task_name = "#{@item.ref_coll}:#{@item.data["_id"]}"
    @task ||= SS::Task.order_by(id: 1).find_or_create_by(site_id: @cur_site.id, name: task_name)
  end

  def ref_item
    return @ref_item if instance_variable_defined?(:@ref_item)
    @ref_item = item.ref_item
  end

  def compare_to_item
    return @compare_to_item if instance_variable_defined?(:@compare_to_item)

    compare_to = params[:compare_to].to_s
    if compare_to.blank?
      @compare_to_item = nil
      return @compare_to_item
    end

    @compare_to_item = @model.where("data.site_id" => @cur_site.id).find(compare_to)
  end

  def check_compare_to
    return unless compare_to_item

    raise "404" if item.ref_coll != compare_to_item.ref_coll
    raise "404" if item.ref_class != compare_to_item.ref_class
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
