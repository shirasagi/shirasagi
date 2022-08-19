module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: Map::Extensions::Points, default: []
      field :map_zoom_level, type: Integer
      field :center_setting, type: String, default: "auto"
      field :set_center_position, type: String
      field :zoom_setting, type: String, default: "auto"
      field :set_zoom_level, type: Integer
      field :map_reference_method, type: String, default: "direct"
      field :map_reference_column_name, type: String
      field :map_link, type: String, default: "hide"
      field :map_goal, type: Integer
      field :map_route, type: String

      permit_params map_points: [ :name, :loc, :text, :link, :image, :number ]
      permit_params :map_zoom_level, :center_setting, :set_center_position, :zoom_setting, :set_zoom_level
      permit_params :map_reference_method, :map_reference_column_name, :map_link, :map_goal, :map_route

      validate :validate_number
      validate :validate_map_goal
      validate :validate_map_route

      after_save :save_geolocation, if: ->{ map_points.present? }
      after_destroy :remove_geolocation

      if respond_to? :liquidize
        liquidize do
          export as: :map_points do
            map_points, _map_options = effective_map_points_and_options
            map_points
          end
          export :map_zoom_level
        end
      end
    end

    def map_options
      options = {}
      if center_setting == "designated_location" && set_center_position.present?
        options[:center] = set_center_position.split(",").map(&:to_f)
      end
      if zoom_setting == "designated_level" && set_zoom_level.present?
        options[:zoom] = set_zoom_level
      end
      options
    end

    def save_geolocation
      if public?
        Map::Geolocation.update_with(self)
      else
        Map::Geolocation.remove_with(self)
      end
    end

    def remove_geolocation
      Map::Geolocation.remove_with(self)
    end

    def map_reference_method_options
      %w(page direct).map do |v|
        [ I18n.t("map.options.map_reference_method.#{v}"), v ]
      end
    end

    def effective_map_points_and_options
      Map::Addon::Page.recursively_retrive_map_points_and_options(@cur_site || self.site, self, 0)
    end

    def self.recursively_retrive_map_points_and_options(cur_site, page, count)
      return [ page.map_points, page.map_options ] if page.map_reference_method == "direct"
      return if count > 3

      page = self.find_map_reference_page(cur_site, page)
      return unless page

      self.recursively_retrive_map_points_and_options(cur_site, page, count + 1)
    end

    def self.find_map_reference_page(cur_site, page)
      return if page.map_reference_column_name.blank?

      map_reference_column = page.column_values.where(name: page.map_reference_column_name).first
      return if map_reference_column.blank? || map_reference_column.page_id.blank?

      Cms::Page.site(cur_site).where(id: map_reference_column.page_id).first
    end

    def map_link_options
      %w(hide show).map do |v|
        [ I18n.t("map.#{v}"), v ]
      end
    end

    def set_map_url
      return if self.map_points.blank?

      url = SS.config.map.googlemaps_route_search_end_point
      if self.map_route.present?
        self.map_route.split(',').each do |route|
          map_points.each do |map_point|
            url += map_point[:loc].reverse.join(',') + "/" if route == map_point[:number]
          end
        end
      else
        map_points = self.map_points.sort_by! { |map_point| map_point[:number].to_i }
        map_points.each do |map_point|
          next if map_point[:number].blank?
          url += map_point[:loc].reverse.join(',') + "/"
        end
        if self.map_goal.present?
          map_points.each do |map_point|
            url += map_point[:loc].reverse.join(',') + "/" if map_point[:number] == self.map_goal.to_s
          end
        end
      end
      url
    end

    def validate_number
      if self.map_points.present?
        self.map_points.group_by { |e| e[:number] }.map do |n, m|
          if n.present?
            if !n.numeric?
              return self.errors.add :map_points, :invalid_number
            elsif n.to_i < 1 || n.to_i > 99
              return self.errors.add :map_points, :invalid_number_range
            elsif m.length > 1
              return self.errors.add :map_points, :uniq_number
            end
          end
        end
      end
    end

    def validate_map_goal
      if self.map_goal.present? && self.map_points.select { |x| x[:number].include?(self.map_goal.to_s) }.blank?
        return self.errors.add :map_goal, :invalid
      end
    end

    def validate_map_route
      if self.map_route.present?
        self.map_route.split(',').each do |n|
          return self.errors.add :map_route, :invalid if !n.numeric?
          return self.errors.add :map_route, :invalid if self.map_points.find_all { |x| x[:number].include?(n) }.blank?
        end
      end
    end
  end
end
