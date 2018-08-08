module Category::Addon
  module Workflow
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      belongs_to :default_route, class_name: "Workflow::Route"
      permit_params :default_route_id
    end

    def default_route_options
      ::Workflow::Route.site(@cur_site).map { |r| [r.name, r.id] }
    end
  end
end
