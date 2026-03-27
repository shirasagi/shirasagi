module SS::Model::Reference
  module UserTitles
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      embeds_ids :titles, class_name: "SS::UserTitle"
      field :title_orders, type: Hash
      before_save :update_title_order

      scope :order_by_title, ->(site) { order_by(order_by_title_params(site)) }
    end

    class_methods do
      def update_all_title_orders(title)
        self.where(title_ids: title.id).find_each do |item|
          item.send(:set_title_order, title.group_id, title.order)
          item.save
        end
      end

      def order_users_by_title(users, cur_site:)
        return users.dup if users.blank? || users.length <= 1

        users.sort do |lhs_user, rhs_user|
          # !!!be careful!!! title_order is descendant
          lhs_title_order = lhs_user.title_orders ? lhs_user.title_orders[cur_site.id].to_i : 0
          rhs_title_order = rhs_user.title_orders ? rhs_user.title_orders[cur_site.id].to_i : 0
          diff = rhs_title_order <=> lhs_title_order
          next diff if diff != 0

          lhs_main_group_order = lhs_user.gws_main_group_orders ? lhs_user.gws_main_group_orders[cur_site.id.to_s].to_i : 0
          rhs_main_group_order = rhs_user.gws_main_group_orders ? rhs_user.gws_main_group_orders[cur_site.id.to_s].to_i : 0
          diff = lhs_main_group_order <=> rhs_main_group_order
          next diff if diff != 0

          # 職員番号を数値として比較（organization_uid_numericフィールドを使用）
          lhs_organization_uid_numeric = lhs_user.organization_uid_numeric || 0
          rhs_organization_uid_numeric = rhs_user.organization_uid_numeric || 0
          diff = lhs_organization_uid_numeric <=> rhs_organization_uid_numeric
          next diff if diff != 0

          diff = lhs_user.uid <=> rhs_user.uid
          next diff if diff != 0

          diff = lhs_user.id <=> rhs_user.id
          next diff if diff != 0

          0
        end
      end

      def order_by_title_params(site)
        @@order_by_title_condition ||= SS.config.gws.order_by_title

        params = {}
        # 1.title_order
        params["title_orders.#{site.id}"] = -1
        # 2.main_group_order
        if @@order_by_title_condition["main_group_order"] == "use"
          params["gws_main_group_orders.#{site.id}"] = 1
        end
        # 3.organization_uid
        if @@order_by_title_condition["organization_uid"] == "numeric"
          params[:organization_uid_numeric] = 1
        else
          params[:organization_uid] = 1
        end
        # 4.uid
        params[:uid] = 1
        params[:id] = 1
        params
      end
    end

    def title(site = nil)
      site ||= cur_site
      return nil if site.blank?
      titles.where(group_id: site.id).first
    end

    def update_title_order(title = nil)
      title ||= self.title

      if title.present?
        set_title_order(title.group_id, title.order)
      else
        remove_title_order
      end
    end

    private

    # def set_title_ids
    #   #
    # end

    def set_title_order(key, value)
      orders = self.title_orders
      orders = {} if orders.nil?

      # hash key must be string
      key = key.to_s

      return if orders[key] == value

      orders[key] = value

      # overwrite with new hash instance
      self.title_orders = orders.deep_dup
    end

    def remove_title_order
      return if cur_site.blank?
      return if title_orders.nil?
      self.title_orders.delete(cur_site.id.to_s)
    end
  end
end
