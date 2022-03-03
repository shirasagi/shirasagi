module SS::Model::Reference
  module UserOccupations
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      embeds_ids :occupations, class_name: "SS::UserOccupation"
      field :occupation_orders, type: Hash
      before_save :update_occupation_order

      scope :order_by_occupation, ->(site) {
        order_by "occupation_orders.#{site.id}" => -1, organization_uid: 1, uid: 1
      }
    end

    class_methods do
      def update_all_occupation_orders(occupation)
        self.where(occupation_ids: occupation.id).each do |item|
          item.send(:set_occupation_order, occupation.group_id, occupation.order)
          item.save
        end
      end
    end

    def occupation(site = nil)
      site ||= cur_site
      return nil if site.blank?
      occupations.where(group_id: site.id).first
    end

    def update_occupation_order(occupation = nil)
      occupation ||= self.occupation

      if occupation.present?
        set_occupation_order(occupation.group_id, occupation.order)
      else
        remove_occupation_order
      end
    end

    private

    def set_occupation_order(key, value)
      orders = self.occupation_orders
      orders = {} if orders.nil?

      # hash key must be string
      key = key.to_s

      return if orders[key] == value

      orders[key] = value

      # overwrite with new hash instance
      self.occupation_orders = orders.deep_dup
    end

    def remove_occupation_order
      return if cur_site.blank?
      return if occupation_orders.nil?
      self.occupation_orders.delete(cur_site.id.to_s)
    end
  end
end
