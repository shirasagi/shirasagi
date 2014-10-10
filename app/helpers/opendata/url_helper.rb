module Opendata::UrlHelper
  def search_datasets_path
    node = Opendata::Node::SearchDataset.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def search_groups_path
    node = Opendata::Node::SearchGroup.site(@cur_site).public.first
    return nil unless node
    node.url
  end
end
