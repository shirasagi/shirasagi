puts "# lsorg"

node = save_node route: "lsorg/node", filename: "organization", name: "組織案内",
  layout_id: @layouts["organization"].id, root_group_ids: [@g_ss.id]
Lsorg::ImportGroupsJob.bind(site_id: @site.id, node_id: node.id).perform_now
