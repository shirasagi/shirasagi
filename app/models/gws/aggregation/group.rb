module Gws::Aggregation
  class Group
    include SS::Document
    include Gws::Referenceable
    include Gws::Reference::Site

    attr_accessor :children, :parent, :descendants, :depth, :trailing_name

    field :activation_date, type: DateTime
    field :expiration_date, type: DateTime

    belongs_to :group, class_name: 'Gws::Group'
    embeds_ids :users, class_name: "Gws::User"

    field :name, type: String
    field :order, type: Integer

    validates :name, presence: true
    validates :group_id, presence: true
    validates :activation_date, presence: true

    default_scope -> { order_by(order: 1, name: 1) }

    def find_user(user_id)
      users.to_a.find { |item| item.id == user_id }
    end

    class << self
      def last_group(group)
        self.where(group_id: group).reorder(created: -1).first
      end

      def active_at(date = Time.zone.now)
        items = where('$and' => [
          { '$or' => [{ :activation_date.lte => date }] },
          { '$or' => [{ expiration_date: nil }, { :expiration_date.gt => date }] }
        ])
        items = items.reorder(name: 1).to_a # tree sort
        GroupArray.new(items)
      end
    end
  end
end
