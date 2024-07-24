class Workflow::BranchCreationService
  include ActiveModel::Model

  attr_accessor :cur_site, :item

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
      else
        copy = item.new_clone
        copy.master = item
        result = copy.save
        
        if !result && copy.errors.any?
          copy.errors.each do |attribute, message|
            item.errors.add(attribute, message)
          end
        end
      end
    end

    result
  end
end
