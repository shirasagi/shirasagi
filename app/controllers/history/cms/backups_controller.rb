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
    @item ||= begin
      item = @model.find(params[:id])
      site_id = item.data.with_indifferent_access['site_id']

      raise "404" if site_id.present? && site_id != @cur_site.id

      item
    end
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

    item.model.relations.each do |k, relation|
      next if relation.class != Mongoid::Association::Embedded::EmbeddedIn

      parent = relation.class_name.constantize.where(
        relation.inverse_of => { "$elemMatch" => { '_id' => compare_to } }
      ).first
      @compare_to_item = parent.send(relation.inverse_of).find(compare_to) rescue nil

      break @compare_to_item if @compare_to_item
    end
    @compare_to_item = @model.find(compare_to)
    site_id = @compare_to_item.data.with_indifferent_access['site_id']

    raise "404" if site_id.present? && site_id != @cur_site.id

    @compare_to_item
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
    if @item.ref_id != @item.data["_id"]
      @item.errors.add :base, :unable_to_restore_branch_page_history
    end
    render
  end

  def update
    if @item.ref_id != @item.data["_id"]
      @item.errors.add :base, :unable_to_restore_branch_page_history
      render action: :restore
      return
    end

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
