class SS::Migration20261023000001
  include SS::Migration::Base

  depends_on "20260427000000"

  def change
    previous_part_link_targets = Set.new(%w(self blank))
    current_part_link_targets = Set.new(%w(_self _blank))
    each_part do |part|
      next if part.link_target.blank?
      next if current_part_link_targets.include?(part.link_target)

      if previous_part_link_targets.include?(part.link_target)
        part.set(link_target: "_#{part.link_target}")
      else
        # 許可外の値が保存されている
        part.unset(:link_target)
      end
    end

    available_page_link_targets = Set.new(%w(_self _blank))
    each_page do |page|
      next if page.link_target.blank?
      next if available_page_link_targets.include?(page.link_target)

      # 許可外の値が保存されている
      page.unset(:link_target)
    end
  end

  private

  def each_part(&block)
    criteria = Ads::Part::Banner.all.exists(link_target: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end

  def each_page(&block)
    criteria = Ads::Banner.all.exists(link_target: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
