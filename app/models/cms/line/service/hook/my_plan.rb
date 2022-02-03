module Cms::Line::Service::Hook
  class MyPlan < Base
    include Cms::Addon::Line::Service::PageList

    def type
      "my_plan"
    end
  end
end
