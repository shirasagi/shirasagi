class Cms::Node::CopyNodesJob < Cms::ApplicationJob
  include Job::SS::TaskFilter
  include Sys::SiteCopy::SsFiles
  include Sys::SiteCopy::CmsRoles
  include Sys::SiteCopy::CmsLayouts
  include Job::Cms::CopyNodes::CmsNodes
  include Sys::SiteCopy::CmsParts
  include Sys::SiteCopy::CmsPages
  include Sys::SiteCopy::CmsFiles
  include Sys::SiteCopy::CmsEditorTemplates
  include Sys::SiteCopy::KanaDictionaries

  self.task_name = "cms:copy_nodes"

  #attr_accessor :target_node_name, :base_node_name, :cur_site, :cur_node

  def perform(target_node_name)
    @cur_site = Cms::Site.find(site_id)
    @cur_node = Cms::Node.find(node_id)
    @target_node_name = target_node_name.values.first
    @base_node_name = @cur_node.filename

    copy_cms_nodes
  end
end
