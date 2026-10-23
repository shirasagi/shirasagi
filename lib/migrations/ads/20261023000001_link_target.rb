class SS::Migration20261023000001
  include SS::Migration::Base

  depends_on "20261023000000"

  def change
    previous_link_targets = Set.new(%w(self blank))
    each_item do |item|
      next if item.link_target.blank?

      if previous_link_targets.include?(item.link_target)
        item.set(link_target: "_#{item.link_target}")
      end
    end
  end

  private

  def each_item(&block)
    criteria = Ads::Part::Banner.all.exists(link_target: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
