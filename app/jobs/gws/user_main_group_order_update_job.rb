class Gws::UserMainGroupOrderUpdateJob < Gws::ApplicationJob
  def perform
    return if !site.gws_use?

    group_ids = [site.id] + site.descendants.pluck(:id)
    # サイトのグループに所属するユーザーを取得
    user_ids_from_groups = Gws::User.in(group_ids: group_ids).pluck(:id)
    # gws_main_group_ordersに値があるユーザーも取得（グループから外れたユーザーも含む）
    order_key = site.id.to_s
    user_ids_with_orders = Gws::User.where("gws_main_group_orders.#{order_key}" => { "$exists" => true }).pluck(:id)
    # 両方のユーザーIDを結合して重複を除去
    user_ids = (user_ids_from_groups + user_ids_with_orders).uniq
    user_ids.each do |user_id|
      user = Gws::User.find_by(id: user_id)
      next if user.nil?

      orders = (user.gws_main_group_orders || {}).dup

      main_group = user.gws_main_group(site)
      if main_group.blank?
        next if orders[order_key].blank?

        Rails.logger.info("clear #{user.long_name}")
        orders.delete(order_key)
        user.set(gws_main_group_orders: orders)
        next
      end

      next if orders[order_key] == main_group.order

      Rails.logger.info("update #{user.long_name} #{main_group.trailing_name}")
      orders[order_key] = main_group.order
      user.set(gws_main_group_orders: orders)
    end
  end
end
