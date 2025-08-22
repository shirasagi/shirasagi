class SS::Migration20250801000000
  include SS::Migration::Base

  depends_on "20250609000000"

  def change
    each_file do |file|
      next if file.site_id.present?

      member = file.try(:member)
      next if member.blank?

      file.set(site_id: member.site_id)
    end
  end

  private

  def each_file(&block)
    %w(member/photo member/blog_page member/temp_file member/node/blog_page).each do |model_name|
      criteria = SS::File.all
      criteria = criteria.where(model: model_name)
      criteria = criteria.exists(site_id: false)

      all_ids = criteria.pluck(:id)
      SS::File.each_file(all_ids, &block)
    end
  end
end
