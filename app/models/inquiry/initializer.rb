# coding: utf-8
module Inquiry
  class Initializer    
    Cms::Node.plugin "inquiry/form"
    
    Inquiry::Node::Form.addon "inquiry/message"
    Inquiry::Node::Form.addon "inquiry/captcha"
    Inquiry::Node::Form.addon "inquiry/notice"
    Inquiry::Node::Form.addon "inquiry/reply"
    
    Inquiry::Column.addon "inquiry/input_setting"
  end
end
