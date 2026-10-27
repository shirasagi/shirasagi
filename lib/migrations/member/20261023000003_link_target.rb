class SS::Migration20261023000003
  include SS::Migration::Base

  depends_on "20261009000000"

  def change
    # ads/part/slide とは異なり self / _self は許可されていない
    previous_part_link_targets = Set.new(%w(blank))
    current_part_link_targets = Set.new(%w(_blank))
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
  end

  private

  def each_part(&block)
    criteria = Member::Part::PhotoSlide.all.exists(link_target: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
