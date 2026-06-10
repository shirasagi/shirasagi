class Cms::Node::DestroyJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:destroy_nodes"

  def perform(*args)
    options = args.extract_options!
    options.symbolize_keys!
    selected_ids = args.first

    return if selected_ids.blank?

    task.log "# #{site.name}"

    nodes = Cms::Node.site(site).in(id: selected_ids)

    ids   = nodes.pluck(:id)
    task.total_count = ids.size

    ids.each do |id|
      task.count
      node = nodes.where(id: id).first
      node.cur_user = user if node.respond_to?(:cur_user)
      next unless node

      if user.present? && !node.allowed?(:delete, user, site: site, node: node)
        task.log "skip delete #{node.name}: permission denied"
        next
      end

      task.log "delete #{node.name}"
      node.destroy
    end
  end
end
