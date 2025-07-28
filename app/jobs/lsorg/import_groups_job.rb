class Lsorg::ImportGroupsJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "lsorg:import"

  def perform(opts = {})
    set_page_nodes
    update_nodes
    close_nodes
  end

  def set_page_nodes
    @page_node_ids = Lsorg::Node::Page.where(site_id: site.id, filename: /^#{node.filename}\//).pluck(:id)
  end

  def update_nodes
    root_groups = node.effective_root_groups
    exclude_groups = node.effective_exclude_groups

    task.log "#{node.t(:root_group_ids)}... #{root_groups.map(&:name).join(", ")}"
    if exclude_groups.present?
      task.log "#{node.t(:exclude_group_ids)}... #{exclude_groups.map(&:name).join(", ")}"
    end

    task.log ""
    task.log "# #{I18n.t("lsorg.notice.update_nodes")}"

    root_groups.each do |root_group|
      root = Lsorg::GroupTree.build(root_group, exclude_groups)
      root.tree.each do |edge|
        update_edge(edge)
      end
    end
  end

  def close_nodes
    return if @page_node_ids.blank?

    task.log ""
    task.log "# #{I18n.t("lsorg.notice.close_nodes")}"

    @page_node_ids.each do |id|
      item = Lsorg::Node::Page.find(id) rescue nil
      next if item.nil?

      item.state = "closed"
      if item.update
        task.log "update #{item.name}"
      else
        task.log "error #{item.name} : #{item.errors.full_messages.join(", ")}"
      end
    end
  end

  def find_or_initialize_node(edge)
    parent = edge.root? ? node : edge.parent.node

    if parent.nil? || parent.invalid? || !parent.persisted?
      return
    end

    #if edge.root?
    #  cond = { site_id: site.id, filename: /^#{parent.filename}\//, depth: (parent.depth + 1), page_group_id: edge.group.id }
    #else
    #  root_node = edge.root.node
    #  cond = { site_id: site.id, filename: /^#{root_node.filename}\//, page_group_id: edge.group.id }
    #end
    cond = { site_id: site.id, filename: /^#{node.filename}\//, page_group_id: edge.group.id }

    item = Lsorg::Node::Page.where(cond).first
    item ||= Lsorg::Node::Page.new

    yield(item, parent) if block_given?

    item
  end

  def update_edge(edge)
    item = find_or_initialize_node(edge) do |item, parent|
      item.cur_site = site
      item.cur_node = parent
      item.page_group_id = edge.group.id

      item.name = edge.name
      item.basename = edge.basename
      item.order = edge.order
      item.layout = layout if item.layout.nil?
      item.group_ids = node.group_ids if item.groups.blank?
    end
    return if item.nil?

    if item.save
      @page_node_ids.delete(item.id)
      task.log "update #{edge.full_name} (#{edge.filename})"
    else
      task.log "error #{edge.full_name} (#{edge.filename}) : #{item.errors.full_messages.join(", ")}"
    end

    edge.node = item
    item
  end

  def layout
    node.page_layout || node.layout
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
