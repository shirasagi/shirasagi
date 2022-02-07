class Map::Geolocation
  include SS::Document
  include Mongoid::Geospatial

  sphere_index :location

  field :location, type: Point, sphere: true

  belongs_to :owner_item, class_name: "Object", polymorphic: true
  belongs_to :site, class_name: "SS::Site"
  field :name, type: String
  field :filename, type: String
  field :depth, type: Integer
  field :category_ids, type: Array, default: []

  before_validation :set_item_attributes, if: ->{ owner_item }
  validates :location, presence: true
  validates :owner_item_id, presence: true

  private

  def set_item_attributes
    if owner_item.class.include?(Cms::Content)
      self.site_id = owner_item.site_id
      self.name = owner_item.name
      self.filename = owner_item.filename
      self.depth = owner_item.depth
      self.category_ids = owner_item.category_ids
    end
  end

  class << self
    def with_item(item)
      self.where(owner_item_id: item.id, owner_item_type: item.class.name)
    end

    def remove_with(item)
      with_item(item).destroy_all
    end

    def update_with(item)
      remove_with(item)
      item.map_points.each do |map_point|
        next if map_point["loc"].blank?
        location = self.new
        location.owner_item = item
        location.location = map_point["loc"]
        location.save
      end
    end

    def geonear(coordinates, limit = 10)
      pipes = []
      pipes << {
        '$geoNear' => {
          near: { type: "Point", coordinates: coordinates },
          distanceField: "distance",
          query: criteria.selector,
          spherical: true
        }
      }
      pipes << { '$limit' => limit }

      items = []
      references = {}
      self.collection.aggregate(pipes).to_a.each do |data|
        id = data["owner_item_id"]
        klass = data["owner_item_type"].constantize
        distance = data["distance"]

        if distance >= 1000
          label = "#{(distance / 1000).round(1)} km"
        else
          label = "#{distance.round(1)} m"
        end
        items << OpenStruct.new({
          id: id,
          distance: distance,
          label: label
        })
        references[klass] ||= []
        references[klass] << id
      end

      # constantize owner_items
      owner_items = {}
      references.each do |klass, ids|
        klass.in(id: ids).to_a.each do |owner_item|
          owner_items[owner_item.id] = owner_item
        end
      end
      items.each do |item|
        item.item = owner_items[item.id]
      end

      items
    end
  end
end
