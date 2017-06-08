module SS::ExifGeoLocation
  extend ActiveSupport::Concern

  included do
    field :geo_location, type: Map::Extensions::Loc
    permit_params geo_location: [:lat, :lng]
  end

  private

  def extract_geo_location(img_list)
    img = img_list[0]
    exif_lat = img.get_exif_by_entry('GPSLatitude')[0][1]
    exif_lng = img.get_exif_by_entry('GPSLongitude')[0][1]
    return if exif_lat.blank? || exif_lng.blank?

    exif_lat = exif_lat.split(',').map(&:strip)
    exif_lng = exif_lng.split(',').map(&:strip)
    latitude = (Rational(exif_lat[0]) + Rational(exif_lat[1]) / 60 + Rational(exif_lat[2]) / 3600).to_f
    longitude = (Rational(exif_lng[0]) + Rational(exif_lng[1]) / 60 + Rational(exif_lng[2]) / 3600).to_f

    exif_lat_ref = img.get_exif_by_entry('GPSLatitudeRef')[0][1]
    latitude *= -1 if exif_lat_ref == 'S'

    exif_lng_ref = img.get_exif_by_entry('GPSLongitudeRef')[0][1]
    longitude *= -1 if exif_lng_ref == 'W'

    self.geo_location = [ latitude, longitude ]
  end
end
