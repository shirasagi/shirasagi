class Gws::Aggregation::GroupUpdateJob < Gws::ApplicationJob
  def perform
    now = Time.zone.now
    actives = Gws::Aggregation::Group.site(site).
      where(:expiration_date.exists => false).to_a
    actives = actives.index_by(&:id)

    # 初期設定
    if actives.blank?
      now = Time.zone.parse(SS.config.gws.aggregation["first_activation_date"])
    end

    Gws::Group.in_group(site).active.tree_sort.each do |group|
      last_group = Gws::Aggregation::Group.site(site).last_group(group)
      last_cond = {}
      if last_group
        last_cond = {
          name: last_group.name,
          user_ids: last_group.user_ids,
          expiration_date: last_group.expiration_date
        }
      end

      users = group.users.active.order_by_title(site)
      current_cond = {
        name: group.name,
        user_ids: users.map(&:id),
        expiration_date: nil
      }

      if last_cond == current_cond
        item = last_group
      else
        item = Gws::Aggregation::Group.new(current_cond)
      end

      item.site = site
      item.group = group
      item.order = group.order

      if item.new_record?
        item.activation_date = now
        Rails.logger.info "change : #{group.name}(#{group.id})"
      end

      item.save!
      actives.delete(item.id)
    end

    actives.each do |_, item|
      item.expiration_date = now
      item.save!
    end
  end
end
