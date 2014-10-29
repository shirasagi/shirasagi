module Facility
  class Initializer
    Cms::Node.plugin "facility/node"
    Cms::Node.plugin "facility/page"
    Cms::Node.plugin "facility/category"
    Cms::Node.plugin "facility/service"
    Cms::Node.plugin "facility/location"
    Cms::Node.plugin "facility/search"
  end
end
