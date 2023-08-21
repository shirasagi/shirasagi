class History::Backup::RestoreJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  def perform(object_id)
    task.log "# #{I18n.t("modules.addons.history/backup")} #{I18n.t("history.buttons.restore")}"
    @item.restore
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
    @item ||= History::Backup.find(arguments.first)
  end
end
