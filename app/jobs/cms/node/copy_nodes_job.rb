class Cms::Node::CopyNodesJob < Cms::ApplicationJob
  include Job::SS::TaskFilter
  include Job::Cms::CopyNodes::SsFiles
  include Job::Cms::CopyNodes::CmsLayouts
  include Job::Cms::CopyNodes::CmsNodes
  include Job::Cms::CopyNodes::CmsParts
  include Job::Cms::CopyNodes::CmsPages

  self.task_name = "cms:copy_nodes"

  def perform(target_node_name={})
    @cur_site = Cms::Site.find(site_id)
    @cur_node = Cms::Node.find(node_id)
    @target_node_name = target_node_name.values.first

    copy_cms_nodes
    copy_cms_pages
    copy_cms_layouts
    copy_cms_parts
  end
end
