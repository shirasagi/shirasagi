class Facility::Map
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Map::Addon::Page
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission

  default_scope ->{ where(route: "facility/map") }
  validate :center_position_validate, if: -> { set_center_position.present? }
  validate :zoom_level_validate, if: -> { set_zoom_level.present? }

  after_save :save_facility

  private

  def save_facility
    parent.becomes_with_route.save rescue nil
  end

  def serve_static_file?
    false
  end

  def center_position_validate
    lonlat = set_center_position.split(',')
    if lonlat.length == 2
      lat = lonlat[1]
      lon = lonlat[0]
      if !lat.numeric? || !lon.numeric?
        self.errors.add :set_center_position, :invalid_latlon
      elsif lat.to_f.floor < -90 || lat.to_f.ceil > 90 || lon.to_f.floor < -180 || lon.to_f.ceil > 180
        self.errors.add :set_center_position, :invalid_latlon
      end
    else
      self.errors.add :set_center_position, :invalid_latlon
    end
  end

  def zoom_level_validate
    if set_zoom_level <= 0 || set_zoom_level > 21
      self.errors.add :set_zoom_level, :invalid_zoom_level
    end
  end
end
