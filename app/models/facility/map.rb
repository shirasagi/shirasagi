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

  private

  def serve_static_file?
    false
  end

  def center_position_validate
    latlon = set_center_position.split(',')
    if latlon.length == 2
      lat = latlon[0]
      lon = latlon[1]
      if !lat.match?(/^([1-9]\d*|0)(\.\d+)?$/) || !lon.match?(/^([1-9]\d*|0)(\.\d+)?$/)
        self.errors.add :set_center_position, :invalid_latlon
      elsif lat.to_i <= -90 || lat.to_i >= 90 || lon.to_i <= -180 || lon.to_i >= 180
        self.errors.add :set_center_position, :invalid_latlon
      end
    else
      self.errors.add :set_center_position, :invalid_latlon
    end
  end
end
