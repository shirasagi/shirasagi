class Map::Geolocation
  include SS::Document
  include SS::Reference::Site
  include Mongoid::Geospatial

  sphere_index :location

  field :location, type: Point, sphere: true

  belongs_to :owner_item, class_name: "Object", polymorphic: true
  field :filename, type: String
  field :category_ids, type: Array

  before_validation :set_owner_item_attributes
  validates :location, presence: true
  validates :owner_item_id, presence: true

  private

  def set_owner_item_attributes
    return unless owner_item
    if owner_item.try(:filename).presence.is_a?(String)
      self.filename = owner_item.filename
    end
    if owner_item.try(:category_ids).presence.is_a?(Array)
      self.category_ids = owner_item.category_ids
    end
  end

  class << self
    def with_owner_item(item)
      self.where(owner_item_id: item.id, owner_item_type: item.class.name)
    end

    def remove_with_owner_item(item)
      with_owner_item(item).destroy_all
    end

    def update_with_facility(facility)
      remove_with_owner_item(facility)
      facility.map_points.each do |map_point|
        next if map_point["loc"].blank?
        item = self.new
        item.site = facility.site
        item.owner_item = facility
        item.location = map_point["loc"]
        item.save
      end
    end
  end
end
