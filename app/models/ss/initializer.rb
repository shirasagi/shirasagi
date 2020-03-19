module SS
  class Initializer
    ActionView::Base.default_form_builder = SS::Helpers::FormBuilder
    ApplicationMailer.set :load_settings

    SS::File.model "ss/temp_file", SS::TempFile
    SS::File.model "ss/thumb_file", SS::ThumbFile
    SS::File.model "ss/user_file", SS::UserFile
    SS::File.model "ss/link_file", SS::LinkFile
    SS::File.model "ss/logo_file", SS::LogoFile

    Liquid::Template.register_filter(SS::LiquidFilters)
    Liquid::Template.default_exception_renderer = lambda do |e|
      Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise e if !Rails.env.production?
    end
  end
end
