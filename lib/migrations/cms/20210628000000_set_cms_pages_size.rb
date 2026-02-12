class SS::Migration20210628000000
  include SS::Migration::Base

  depends_on "20210622000000"

  def change
    each_page do |page|
      # page.try(:new_size_input)
      html_size = page.try(:html_bytesize) || 0
      page.set(size: html_size + owned_files_bytesize(page))
    end
  end

  private

  def each_page
    criteria = Cms::Page.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(1_000) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        site = id_to_site_map[page.site_id]
        next unless site

        page.cur_site = site
        page.site = site

        yield page
      end
    end
  end

  def owned_files_bytesize(page)
    owned_files = owner_item_to_files_map["#{page.class.name}:#{page.id}"]
    return 0 if owned_files.blank?

    owned_files.sum { _1.size } || 0
  end

  def all_sites
    @all_sites ||= Cms::Site.all.to_a
  end

  def id_to_site_map
    @id_to_site_map ||= all_sites.index_by(&:id)
  end

  def all_files
    @all_files ||= begin
      criteria = SS::File.all
      criteria = criteria.where(owner_item_type: { "$exists" => true }, owner_item_id: { "$exists" => true })
      criteria.only(:owner_item_type, :owner_item_id, :size).to_a
    end
  end

  def owner_item_to_files_map
    @owner_item_to_file_map ||= begin
      all_files
        .select { _1.owner_item_type.present? && _1.owner_item_id.present? }
        .group_by { "#{_1.owner_item_type}:#{_1.owner_item_id}" }
    end
  end
end
