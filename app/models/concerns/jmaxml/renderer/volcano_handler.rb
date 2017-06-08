module Jmaxml::Renderer::VolcanoHandler
  extend ActiveSupport::Concern
  include Jmaxml::Helper::VolcanoHandler

  included do
    template_variable_handler(:volcano_headline, :template_variable_handler_volcano_headline)
    template_variable_handler(:volcano_activity, :template_variable_handler_volcano_activity)
    template_variable_handler(:volcano_prevention, :template_variable_handler_volcano_prevention)
    template_variable_handler(:appendix, :template_variable_handler_appendix)
  end

  private

  def template_variable_handler_volcano_headline(*_)
    volcano_info_content_volcano_headline
  end

  def template_variable_handler_volcano_activity(*_)
    volcano_info_content_volcano_activity
  end

  def template_variable_handler_volcano_prevention(*_)
    volcano_info_content_volcano_prevention
  end

  def template_variable_handler_appendix(*_)
    volcano_info_content_appendix
  end
end
