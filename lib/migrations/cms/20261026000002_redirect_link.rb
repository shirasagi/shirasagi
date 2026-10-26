class SS::Migration20261026000002
  include SS::Migration::Base

  depends_on "20261026000000"

  def change
    each_content do |content|
      next if content.redirect_link.blank?

      redirect_link = content.redirect_link
      if UrlValidator.valid?(redirect_link, absolute_path: true)
        redirect_link = SS.follow_up_url_encode!(redirect_link) rescue nil
      else
        redirect_link = nil
      end

      if redirect_link.nil?
        content.unset(:redirect_link)
      elsif redirect_link != content.redirect_link
        content.set(redirect_link: redirect_link)
      end
      FileUtils.rm_rf(content.path)
    end
  end

  private

  def each_content(&block)
    Cms::Page.all.tap do |criteria|
      criteria = criteria.exists(redirect_link: true)
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        criteria.in(id: ids).each(&block)
      end
    end

    Cms::Node.all.tap do |criteria|
      criteria = criteria.exists(redirect_link: true)
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        criteria.in(id: ids).each(&block)
      end
    end
  end
end
