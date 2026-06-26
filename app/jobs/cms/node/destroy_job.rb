class Cms::Node::DestroyJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:destroy_nodes"

  def perform(*args)
    options = args.extract_options!
    options.symbolize_keys!
    selected_ids = args.first

    return if selected_ids.blank?

    task.log "caution: user not found" if user.blank?
    task.log "# #{site.name}"

    items = Cms::Node.site(site).in(id: selected_ids).to_a

    task.total_count = items.count
    items.each do |item|
      task.count
      item.cur_user = user if item.respond_to?(:cur_user)

      if user.present? && !item.allowed?(:delete, user, site: site, node: node)
        task.log "skip delete #{item.name}: permission denied"
        next
      end

      task.log "delete #{item.name}"
      item.destroy
    end
  end
end
