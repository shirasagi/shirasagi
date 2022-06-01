module Cms::Line::Service
  class Group
    include Cms::Model::Line::ServiceGroup
    include Cms::Addon::Line::Service::Hub
    include Cms::Addon::Line::Service::Hook
    set_permission_name "cms_line_services", :use

    def processor(site, node, client, request)
      item = Cms::Line::Service::Processor::Hub.new(
        service: self,
        site: site,
        node: node,
        client: client,
        request: request)
      item.parse_request
      item
    end
  end
end
