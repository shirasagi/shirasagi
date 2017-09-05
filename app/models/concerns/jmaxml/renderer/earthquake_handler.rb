module Jmaxml::Renderer::EarthquakeHandler
  extend ActiveSupport::Concern
  include Jmaxml::Helper::EarthquakeHandler

  included do
    template_variable_handler(:earthquake_origin_time, :template_variable_handler_earthquake_origin_time)
    template_variable_handler(:earthquake_magnitude, :template_variable_handler_earthquake_magnitude)
    template_variable_handler(:hypocenter_area_name, :template_variable_handler_hypocenter_area_name)
    template_variable_handler(:hypocenter_coordinate, :template_variable_handler_hypocenter_coordinate)
    template_variable_handler(:hypocenter_name_from_mark, :template_variable_handler_hypocenter_namefrommark)
  end

  private

  def template_variable_handler_earthquake_origin_time(*_)
    body_earthquake_origin_time_format
  end

  def template_variable_handler_earthquake_magnitude(*_)
    body_earthquake_magnitude
  end

  def template_variable_handler_hypocenter_area_name(*_)
    body_earthquake_hypocenter_area_name
  end

  def template_variable_handler_hypocenter_coordinate(*_)
    body_earthquake_hypocenter_area_coordinate
  end

  def template_variable_handler_hypocenter_namefrommark(*_)
    body_earthquake_hypocenter_area_namefrommark
  end
end
