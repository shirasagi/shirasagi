class History::Trash::RestoreJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  def perform(object_id, options)
    restore_params = options[:restore_params]
    file_params = options[:file_params]

    task.log "# #{I18n.t("mongoid.models.history/trash")} #{I18n.t("history.buttons.restore")}"

    if @item.ref_coll == "ss_files"
      cur_group_id = file_params.delete(:cur_group)
      file_params[:cur_group] = Cms::Group.find(cur_group_id)
      file_params[:cur_user] = user

      @item.file_restore!(file_params)
    else
      result = @item.restore!(restore_params)
      @item.children.restore!(restore_params) if restore_params[:children] == 'restore' && @item.ref_coll == 'cms_nodes' && result
    end

    @item.errors.full_messages
  end

  private

  def task_cond
    set_item!

    task_name = "#{@item.ref_coll}:#{@item.data["_id"]}"
    cond = { name: task_name }
    cond[:site_id] = site_id
    cond
  end

  def set_item!
    @item ||= History::Trash.find(arguments.first)
  end
end
