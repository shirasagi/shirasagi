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

  def build_path(url, options)
    return url if options.blank?
    # see: Rails Named Route Collection Source Code
    # https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/routing/route_set.rb
    ActionDispatch::Http::URL.path_for(path: url, params: options)
  end

  def dataset_path(options = {})
    node = Opendata::Node::Dataset.site(@cur_site).public.first
    raise "dataset search is disabled since Opendata::Node::Dataset is not registered" unless node
    build_path(node.url, options)
  end

  def search_datasets_path(options = {})
    node = Opendata::Node::SearchDataset.site(@cur_site).public.first
    raise "dataset search is disabled since Opendata::Node::SearchDataset is not registered" unless node
    build_path(node.url, options)
  end

  def search_groups_path(options = {})
    node = Opendata::Node::SearchDatasetGroup.site(@cur_site).public.first
    raise "group search is disabled since Opendata::Node::SearchDatasetGroup is not registered" unless node
    build_path(node.url, options)
  end

  def search_apps_path(options = {})
    node = Opendata::Node::SearchApp.site(@cur_site).public.first
    raise "app search is disabled since Opendata::Node::SearchApp is not registered" unless node
    build_path(node.url, options)
  end

  def search_ideas_path(options = {})
    node = Opendata::Node::SearchIdea.site(@cur_site).public.first
    raise "idea search is disabled since Opendata::Node::SearchIdea is not registered" unless node
    build_path(node.url, options)
  end

  def sparql_path(options = {})
    node = Opendata::Node::Sparql.site(@cur_site).public.first
    raise "sparql is disabled since Opendata::Node::Sparql is not registered" unless node
    build_path(node.url, options)
  end

  def mypage_path(options = {})
    node = Opendata::Node::Mypage.site(@cur_site).public.first
    raise "mypage is disabled since Opendata::Node::Mypage is not registered" unless node
    build_path(node.url, options)
  end

  def my_dataset_path(options = {})
    node = Opendata::Node::MyDataset.site(@cur_site).public.first
    raise "mypage is disabled since Opendata::Node::MyDataset is not registered" unless node
    build_path(node.url, options)
  end

  def my_idea_path(options = {})
    node = Opendata::Node::MyIdea.site(@cur_site).public.first
    raise "mypage is disabled since Opendata::Node::MyIdea is not registered" unless node
    build_path(node.url, options)
  end

  def member_path(options = {})
    node = Opendata::Node::Member.site(@cur_site).public.first
    raise "member is disabled since Opendata::Node::Member is not registered" unless node
    build_path(node.url, options)
  end

  def member_login_path(options = {})
    node = Member::Node::Login.site(@cur_site).public.first
    raise "member login is disabled since Member::Node::Login is not registered" unless node
    build_path(node.url, options)
  end
end
