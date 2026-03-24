module SS::Model::Reference
  module UserTitles
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      embeds_ids :titles, class_name: "SS::UserTitle"
      field :title_orders, type: Hash
      before_save :update_title_order

      scope :order_by_title, ->(site) {
        alpha_first = site.respond_to?(:organization_uid_alpha_first?) && site.organization_uid_alpha_first?
        type_dir = alpha_first ? 1 : -1
        order_by(
          "title_orders.#{site.id}" => -1,
          "gws_main_group_orders.#{site.id}" => 1,
          organization_uid_type: type_dir,
          organization_uid_sort_key: 1,
          uid: 1,
          id: 1
        )
      }
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

        alpha_first = cur_site.respond_to?(:organization_uid_alpha_first?) && cur_site.organization_uid_alpha_first?

        users.sort do |lhs_user, rhs_user|
          # ① 役職（降順）
          lhs_title_order = lhs_user.title_orders ? lhs_user.title_orders[cur_site.id].to_i : 0
          rhs_title_order = rhs_user.title_orders ? rhs_user.title_orders[cur_site.id].to_i : 0
          diff = rhs_title_order <=> lhs_title_order
          next diff if diff != 0

          # ② 主管課（昇順）
          lhs_main_group_order = lhs_user.gws_main_group_orders ? lhs_user.gws_main_group_orders[cur_site.id.to_s].to_i : 0
          rhs_main_group_order = rhs_user.gws_main_group_orders ? rhs_user.gws_main_group_orders[cur_site.id.to_s].to_i : 0
          diff = lhs_main_group_order <=> rhs_main_group_order
          next diff if diff != 0

          # ③ 職員番号の種別（alpha/numeric、サイト設定に応じて昇順or降順）
          lhs_type = lhs_user.organization_uid_type.to_s
          rhs_type = rhs_user.organization_uid_type.to_s
          diff = alpha_first ? (lhs_type <=> rhs_type) : (rhs_type <=> lhs_type)
          next diff if diff != 0

          # ④ 職員番号のソートキー（昇順）
          lhs_sort_key = lhs_user.organization_uid_sort_key.to_s
          rhs_sort_key = rhs_user.organization_uid_sort_key.to_s
          diff = lhs_sort_key <=> rhs_sort_key
          next diff if diff != 0

          diff = lhs_user.uid.to_s <=> rhs_user.uid.to_s
          next diff if diff != 0

          lhs_user.id <=> rhs_user.id
        end
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
