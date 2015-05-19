module Opendata::UrlHelper
  def member_icon(member, opts = {})
    opts[:alt] ||= ""
    if opts[:size]
      opts.merge!(width: 38, height: 38) if opts[:size] == :small
      opts.delete :size
    end

    url = member.icon ? member.icon.url : "opendata/icon-user.png"
    image_tag url, opts
  end

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

  def search_apps_path
    node = Opendata::Node::SearchApp.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def search_ideas_path
    node = Opendata::Node::SearchIdea.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def sparql_path
    node = Opendata::Node::Sparql.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def mypage_path
    node = Opendata::Node::Mypage.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def member_path
    node = Opendata::Node::Member.site(@cur_site).public.first
    return nil unless node
    node.url
  end

  def mypage_path
    node = Opendata::Node::Mypage.site(@cur_site).public.first
    return nil unless node
    node.url
  end
end
