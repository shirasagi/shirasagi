module Sys::SiteCopy::CmsPages
  extend ActiveSupport::Concern
  include SS::Copy::CmsPages
  include Sys::SiteCopy::CmsContents

  def copy_cms_page(src_page)
    Rails.logger.info("♦︎ コピー開始: #{src_page.filename}(#{src_page.id}), route: #{src_page.route}")

    return nil if (src_page.route != "cms/page") && !@copy_contents.include?('pages')

    Rails.logger.debug("♦︎ copy_cms_page: #{@copy_contents.inspect}") # 📌 copy_contents の状態を確認
    Rails.logger.debug("♦︎ copy_cms_page: src_page.contact_group_contact_id=#{src_page.contact_group_contact_id}") # 📌 Contact ID 確認

    copy_cms_content(:pages, src_page, copy_cms_page_options)

    # サマリーページのコピー後に category_node の summary_page_id を更新
    dest_page = Cms::Page.site(@dest_site).find_by(filename: src_page.filename)
    if src_page.route == "cms/summary_page"
      update_summary_page_reference(src_page, dest_page)
    end

  rescue => e
    @task.log("#{src_page.filename}(#{src_page.id}): ページのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_pages
    page_ids = Cms::Page.site(@src_site).pluck(:id)
    Rails.logger.info("♦︎ コピー対象ページ数: #{page_ids.size}") # 📌 ページ数確認
    page_ids.each do |page_id|
      page = Cms::Page.site(@src_site).find(page_id) rescue nil
      if page.blank?
        Rails.logger.warn("♦︎ ページ取得失敗: page_id=#{page_id}")
        next
      end
      # next if page.blank?
      Rails.logger.info("♦︎ ページコピー開始: #{page.filename} (#{page.id})")
      copy_cms_page(page)
    end
  end

  private

  def update_summary_page_reference(src_page, dest_page)
    if dest_page.nil?
      Rails.logger.error("♦︎ update_summary_page_reference: dest_page が nil のため更新できません")
      return
    end

    category_nodes = Cms::Node.site(@src_site).where(summary_page_id: src_page.id)

    category_nodes.each do |category_node|
      dest_category_node = Cms::Node.site(@dest_site).find_by(filename: category_node.filename)
      if dest_category_node.blank?
        Rails.logger.warn("♦︎ カテゴリーノード未検出: #{category_node.filename}")
        next
      end

      Rails.logger.info("♦︎ summary_page_id 更新: #{dest_category_node.filename} -> #{dest_page.id}")
      dest_category_node.update(summary_page_id: dest_page.id)
    end
  end

  def resolve_page_reference(id)
    cache(:pages, id) do
      src_page = Cms::Page.site(@src_site).find(id) rescue nil
      if src_page.blank?
        Rails.logger.warn("#{id}: 参照されているページが存在しません。")
        return nil
      end

      Rails.logger.info("♦︎ 参照ページコピー開始: #{src_page.filename} (#{src_page.id})")
      dest_page = copy_cms_page(src_page)
      Rails.logger.debug("♦︎ コピー後の dest_page: #{dest_page&.id}") # 📌 コピー結果確認
      dest_page.try(:id)
    end
  end
end
