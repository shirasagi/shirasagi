module SS
  class Initializer
    SS::Config
    ActionView::Base.default_form_builder = SS::Helpers::FormBuilder
    ApplicationMailer.set :load_settings
  end
end
