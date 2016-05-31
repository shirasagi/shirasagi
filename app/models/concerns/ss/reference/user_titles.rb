module SS::Reference
  module UserTitles
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      embeds_ids :titles, class_name: "SS::UserTitle"
      field :title_orders, type: Hash
      before_save :update_title_order

      scope :order_by_title, ->(site) {
        order_by "title_orders.#{site.id}" => -1, uid: 1
      }
    end

    class_methods do
      def update_all_title_orders(title)
        self.where(title_ids: title.id).each do |item|
          item.send(:set_title_order, title.group_id, title.order)
          item.save
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
