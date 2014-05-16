# coding: utf-8
module SS
  class Initializer
    SS::Config
    ActionView::Base.default_form_builder = SS::Helpers::FormBuilder
  end
end
