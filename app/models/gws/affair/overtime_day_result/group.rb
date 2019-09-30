class Gws::Affair::OvertimeDayResult::Group
  include SS::Document
  include Gws::Referenceable

  attr_accessor :children
  attr_accessor :parent
  attr_accessor :descendants
  attr_accessor :overall_group_codes
  attr_accessor :depth
  attr_accessor :trailing_name

  field :activation_date, type: DateTime
  field :expiration_date, type: DateTime

  belongs_to :group, class_name: 'Gws::Group'
  embeds_ids :users, class_name: "Gws::User"

  field :name, type: String
  field :group_code, type: String
  field :order, type: Integer

  validates :name, presence: true
  validates :group_id, presence: true
  validates :activation_date, presence: true

  default_scope -> { order_by(order: 1, name: 1) }

  class << self
    def active_at(date)
      items = where('$and' => [
        { '$or' => [{ :activation_date.lte => date }] },
        { '$or' => [{ expiration_date: nil }, { :expiration_date.gt => date }] }
      ])
      items = items.reorder(name: 1).to_a # tree sort

      items.each do |item|
        set_depth(item, items)
      end
      items.each do |item|
        set_children(item, items)
        set_descendants(item, items)
      end

      items
    end

    def set_depth(item, groups)
      item.depth = begin
        count = 0
        full_name = ""
        item.name.split('/').map do |part|
          full_name << "/" if full_name.present?
          full_name << part

          break if item.name == full_name

          found = groups.select { |group| group.name == full_name }
          break if found.blank?

          count += 1
        end
        count
      end
      item.trailing_name = item.name.split("/")[item.depth..-1].join("/")
    end

    def set_children(item, groups)
      item.children = []
      groups.each do |group|
        if (group.name =~ /^#{item.name}\//) && (group.depth == item.depth + 1)
          item.children << group
        end
        if (item.name =~ /^#{group.name}\//) && (item.depth == group.depth + 1)
          item.parent = group
        end
      end
    end

    def set_descendants(item, groups)
      item.descendants = groups.select { |group| group.name =~ /^#{item.name}\// }
      item.overall_group_codes = [item.group_code]
      item.overall_group_codes += item.descendants.map { |group| group.group_code }
      item.overall_group_codes = item.overall_group_codes.select(&:present?)
    end
  end
end
