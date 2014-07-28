# coding: utf-8
module Inquiry::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^inquiry\//) }
  end

  class Form
    include Cms::Node::Model

    default_scope ->{ where(route: "inquiry/form") }
  end
end
