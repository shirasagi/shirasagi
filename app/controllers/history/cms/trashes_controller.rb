class History::Cms::TrashesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model History::Trash

  navi_view "cms/main/navi"

  private

  # overwrite
  def get_params
    return fix_params if params[:item].blank?
    super
  end

  def file_params
    { cur_user: @cur_user, cur_group: @cur_group }
  end

  def set_task
    task_name = "#{@item.ref_coll}:#{@item.data["_id"]}"
    @task ||= SS::Task.order_by(id: 1).find_or_create_by(site_id: @cur_site.id, name: task_name)
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @ref_coll_options = [Cms::Node, Cms::Page, Cms::Part, Cms::Layout, SS::File].collect do |model|
      [model.model_name.human, model.collection_name]
    end
    @ref_coll_options.unshift([I18n.t('ss.all'), 'all'])
    set_items
    @s = OpenStruct.new params[:s]
    @s[:ref_coll] ||= 'all'
    @items = @items.search(@s)
      .order_by(created: -1)
      .page(params[:page])
      .per(50)
  end

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    set_task
    if !@task.ready
      @item.errors.add :base, :other_task_is_running
      render
      return
    end

    if @item.ref_coll == "ss_files"
      file_params = { cur_group: @cur_group.id }
    else
      restore_params = get_params
      restore_params = restore_params.to_unsafe_h if restore_params.respond_to?(:to_unsafe_h)
    end

    job_class = History::Trash::RestoreJob.bind(site_id: @cur_site, user_id: @cur_user)
    error_messages = job_class.perform_now(
      @item.id.to_s, restore_params: restore_params, file_params: file_params
    )
    if error_messages.present?
      error_messages.each { |error_message| @item.errors.add :base, error_message }
      result = false
    else
      result = true
    end

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { template: "undo_delete" }
    render_opts[:notice] = t('ss.notice.restored')

    render_update result, render_opts
  rescue Job::SizeLimitPerUserExceededError => _e
    @item.errors.add :base, :other_task_is_running
    render
  end
end
