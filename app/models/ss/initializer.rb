module SS
  class Initializer
    ActionView::Base.default_form_builder = SS::Helpers::FormBuilder
    ApplicationMailer.set :load_settings

    SS::File.model "ss/temp_file", SS::TempFile
    SS::File.model "ss/thumb_file", SS::ThumbFile
    SS::File.model "ss/user_file", SS::UserFile
  end
end
