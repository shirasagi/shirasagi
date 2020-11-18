class SS::Migration20200625000000
  include SS::Migration::Base

  depends_on "20200526000000"

  def change
    # ページのサムネイルに障害があり、複製元ページと複製したページとで同じサムネイルが共有される問題があった。
    # この共有を修正するマイグレーションである。
    group_by_thumb do |thumb_id, pages|
      next if pages.length <= 1

      file = ::SS::File.where(id: thumb_id).first
      next if file.blank? # unable to fix because thumb has been deleted

      file = file.becomes_with_model

      owner_item = file.owner_item

      pages.each do |page|
        next if page.site.blank? # unable to fix because site has been deleted

        page = page.becomes_with_route
        next if equal_page?(owner_item, page)

        new_file = clone_file(page, file)
        page.set(thumb_id: new_file.id) if new_file.present?
      end
    end
  end

  private

  def group_by_thumb
    criteria = Cms::Page.unscoped.exists(thumb_id: true)
    all_thumb_ids = criteria.pluck(:thumb_id).sort.uniq
    all_thumb_ids.each_slice(20) do |thumb_ids|
      pages = criteria.in(thumb_id: thumb_ids).to_a
      pages.group_by { |page| page.thumb_id }.each do |thumb_id, pages|
        yield thumb_id, pages
      end
    end
  end

  def equal_page?(lhs, rhs)
    return false unless lhs.is_a?(Cms::Model::Page)
    return false unless rhs.is_a?(Cms::Model::Page)
    return false unless lhs.id == rhs.id
    true
  end

  def clone_file(page, file)
    user = page.user
    user ||= begin
      Cms::User.unscoped.in(group_ids: page.group_ids).active.first
    end
    user ||= begin
      Cms::User.unscoped.site(page.site).active.first
    end
    return if user.blank?

    attr = Hash[file.attributes.except(*SS::File::COPY_SKIP_ATTRS)]
    attr.symbolize_keys!
    attr[:model] = file.model
    attr[:site] = page.site
    attr[:user] = attr[:cur_user] = user
    file.class.create_empty!(attr) do |new_file|
      ::FileUtils.copy(file.path, new_file.path)
    end
  end
end
