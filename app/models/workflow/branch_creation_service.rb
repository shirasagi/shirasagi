class Workflow::BranchCreationService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :item
  attr_reader :new_branch

  def call
    item.cur_node ||= item.parent
    if item.branch?
      item.errors.add :base, I18n.t("workflow.branch_message")
      return false
    end
    if item.branches.present?
      item.error.add :base, :branch_is_already_existed
      return false
    end

    task = SS::Task.find_or_create_for_model(item, site: cur_site)

    result = nil
    rejected = -> do
      item.errors.add :base, :other_task_is_running
      result = false
    end
    task.run_with(rejected: rejected) do
      task.log "# #{I18n.t("workflow.branch_page")} #{I18n.t("ss.buttons.new")}"

      item.reload
      if item.branches.present?
        item.error.add :base, :branch_is_already_existed
        result = false
        task.log "failed\n#{item.errors.full_messages.join("\n")}"
      else
        copy = item.new_clone
        copy.master = item
        # 複製の際は公開日時はクリアされるのが望ましいかもしれないが、 差し替えページの場合は引き継がれるのが望ましい。
        # 公開日時種別が「手動の」の場合は特に
        copy.released = item.released if item.released_type == "fixed"
        result = copy.save

        if result
          @new_branch = copy
          task.log "created #{@new_branch.filename}(#{@new_branch.id})"
        elsif copy.errors.any?
          SS::Model.copy_errors(copy, item)
          task.log "failed\n#{copy.errors.full_messages.join("\n")}"
        end
      end
    end

    result
  end
end
