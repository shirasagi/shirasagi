class Cms::Line::Service::Processor::ImageMap < Cms::Line::Service::Processor::Base
  def start_messages
    service.image_map_object
  end
end
