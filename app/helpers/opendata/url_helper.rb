module Opendata::UrlHelper
  def search_datasets_path
    node = Opendata::Node::SearchDataset.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def search_groups_path
    node = Opendata::Node::SearchDatasetGroup.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def sparql_path
    node = Opendata::Node::Sparql.site(@cur_site).public.first
    return nil unless node
    node.url
  end
end
