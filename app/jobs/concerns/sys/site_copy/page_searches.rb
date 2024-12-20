module Sys::SiteCopy::PageSearches
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_cms_page_search(src_item)
    model = Cms::PageSearch
    dest_item = nil
    options = copy_cms_page_search_options
    unsafe_attrs = resolve_unsafe_references(src_item, Cms::PageSearch)
    # なぜかlayoutがsafeなリファレンスとして定義されているので明示的に解決する
    unsafe_attrs["search_layout_ids"] ||= resolve_reference(:layout, src_item.search_layout_ids)

    id = cache(:page_searches, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = page_search_attributes(src_item, model, @dest_site).merge(unsafe_attrs)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      options[:after].call(src_item) if options[:after]
    end

  end

  def copy_cms_page_searches
    model = Cms::PageSearch
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_cms_page_search(item)
    end
  end

  def page_search_attributes(src_item, model, dest_site)
    cate = Category::Node::Base.site(src_item.site).first
    dest_cate = Category::Node::Base.site(dest_site).where(filename: cate.filename).first

    {
      name: src_item.name,
      order: src_item.order,
      search_name: src_item.search_name,
      search_filename: src_item.search_filename,
      search_keyword: src_item.search_keyword,
      search_category_ids: [ dest_cate.id ],
      search_group_ids: src_item.search_group_ids,
      search_user_ids: src_item.search_user_ids,
      search_node_ids: [ dest_cate.id ],
      search_routes: src_item.search_routes,
      search_released_condition: src_item.search_released_condition,
      search_released_start: src_item.search_released_start,
      search_released_close: src_item.search_released_close,
      search_released_after: src_item.search_released_after,
      search_updated_condition: src_item.search_updated_condition,
      search_updated_start: src_item.search_updated_start,
      search_updated_close: src_item.search_updated_close,
      search_updated_after: src_item.search_updated_after,
      search_state: src_item.search_state,
      search_first_released: nil,
      search_approver_state: src_item.search_approver_state,
      search_sort: src_item.search_sort
    }
  end

  private

  def copy_cms_page_search_options
    {
      before: method(:before_copy_cms_page_search),
      after: method(:after_copy_cms_page_search)
    }
  end

  def before_copy_cms_page_search(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): ページ検索のコピーを開始します。")
  end

  def after_copy_cms_page_search(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): ページ検索をコピーしました。")
  end
end

puts @dest_item
