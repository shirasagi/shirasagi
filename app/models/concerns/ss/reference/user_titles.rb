module SS::Reference
  module UserTitles
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      embeds_ids :titles, class_name: "SS::UserTitle"
      field :title_orders, type: Hash
      before_save :update_title_order
    end

    class_methods do
      def update_all_title_orders(title)
        self.where(title_ids: title.id).each do |item|
          item.send(:set_title_order, title)
          item.save
        end
      end
    end

    def title
      return nil if cur_site.blank?
      titles.where(group_id: cur_site.id).first
    end

    def update_title_order(title = nil)
      title ||= self.title

      if title.present?
        set_title_order(title)
      else
        remove_title_order
      end
    end

    private
      # def set_title_ids
      #   #
      # end

      def set_title_order(title)
        orders = self.title_orders
        orders = {} if orders.nil?

        return if orders[title.group_id.to_s] == title.order

        # hash key must be string
        orders[title.group_id.to_s] = title.order

        # overwrite with new hash instance
        self.title_orders = orders.deep_dup
      end

      def remove_title_order
        return if cur_site.blank?

        orders = self.title_orders
        return if orders.blank?
        return unless orders.key?(cur_site.id.to_s)

        orders.delete(cur_site.id.to_s)

        # overwrite with new hash instance
        self.title_orders = orders.deep_dup
      end
  end
end
