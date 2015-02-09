module Inquiry::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^inquiry\//) }
  end

  class Form
    include Cms::Node::Model
    include Inquiry::Addon::Message
    include Inquiry::Addon::Captcha
    include Inquiry::Addon::Notice
    include Inquiry::Addon::Reply

    has_many :columns, class_name: "Inquiry::Column"
    has_many :answers, class_name: "Inquiry::Answer"

    default_scope ->{ where(route: "inquiry/form") }
  end
end
