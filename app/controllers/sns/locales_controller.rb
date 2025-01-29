class Sns::LocalesController < ApplicationController
  LOCALE_PATH = Rails.root.join("app/assets/builds/locales")

  def default
    safe_params = params.permit(:namespace, :languages, :format)
    languages = safe_params[:languages].split("+").map(&:strip)
    ns = safe_params[:namespace]

    if languages.blank? || ns.blank? || ns != "translation"
      head :not_found
      return
    end

    languages.uniq!
    languages.sort!
    basename = SS::FilenameUtils.convert_to_url_safe_japanese(languages.join("+")) + ".json"
    locale_file = LOCALE_PATH.join(basename)
    if ::File.exist?(locale_file)
      if need_to_rebuild?(::File.mtime(locale_file))
        generate_locale languages, ns
      end
    else
      generate_locale languages, ns
    end

    unless ::File.exist?(locale_file)
      head :not_found
      return
    end

    response.headers["Last-Modified"] = CGI::rfc1123_date(::File.mtime(locale_file).in_time_zone)
    send_file locale_file, type: json_content_type, x_sendfile: true
  end

  def fallback
    raise NotImplementedError
  end

  private

  def need_to_rebuild?(base_timestamp)
    base_timestamp = base_timestamp.in_time_zone

    Rails.application.config.i18n.load_path.any? do |path|
      timestamp = ::File.mtime(path).in_time_zone rescue nil
      timestamp && base_timestamp < timestamp
    end
  end

  def generate_locale(languages, ns)
    basename = SS::FilenameUtils.convert_to_url_safe_japanese(languages.join("+")) + ".json"
    languages_locale_file = LOCALE_PATH.join(basename)

    ::Fs.safe_create(languages_locale_file) do |f|
      f.write("{")

      first = true
      languages.each do |lang|
        next unless I18n.available_locales.include?(lang.to_sym)

        json = I18n.t(".", locale: lang).to_json
        json.gsub!(/%{\w+?}/) do |matched|
          "{{#{matched[2..-2]}}}"
        end

        f.write(",") unless first

        f.write("\"#{lang}\":")
        f.write("{\"#{ns}\":#{json}}")
        first = false
      end

      f.write("}")
    end
  end
end
