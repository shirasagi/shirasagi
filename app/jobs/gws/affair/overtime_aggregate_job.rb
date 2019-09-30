class Gws::Affair::OvertimeAggregateJob < SS::ApplicationJob
  def perform
    now = Time.zone.now
    actives = Gws::Affair::OvertimeDayResult::Group.
      where(:expiration_date.exists => false).
      map { |item| [item.id, item] }.to_h

    # 初期設定
    now = Time.zone.parse("2000/1/1") if actives.blank?

    Gws::Group.active.each do |group|
      cond = {
        group_id: group.id,
        name: group.name,
        group_code: group.group_code,
        user_ids: group.users.active.pluck(:id)
      }
      item = Gws::Affair::OvertimeDayResult::Group.find_or_initialize_by(cond)
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
