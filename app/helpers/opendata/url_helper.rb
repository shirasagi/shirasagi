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

  def escape(string)
    URI.escape(string.to_s, Regexp.new("[^#{URI::PATTERN::ALNUM}]"))
  end

  def build_path(url, options)
    return url if options.blank?

    params = options.map do |key, value|
      if value.present?
        "#{escape(key)}=#{escape(value)}"
      else
        "#{escape(key)}"
      end
    end
    "#{url}?#{params.join("&")}".html_safe
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

  def member_path(options = {})
    node = Opendata::Node::Member.site(@cur_site).public.first
    raise "member is disabled since Opendata::Node::Member is not registered" unless node
    build_path(node.url, options)
  end
end
