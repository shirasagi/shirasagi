class Sns::LocalesController < ApplicationController
  def default
    safe_params = params.permit(:namespace, :languages)
    languages = safe_params[:languages].split("+").map(&:strip)
    ns = safe_params[:namespace]

    if languages.blank? || ns.blank?
      head :not_found
      return
    end

    # inefficiency, I know.
    ret = {}
    I18n.available_locales.each do |lang|
      next unless languages.include?(lang.to_s)

      json = I18n.t(".", locale: lang).to_json
      json.gsub!(/%{\w+?}/) do |matched|
        "{{#{matched[2..-2]}}}"
      end

      ret[lang] = { ns => JSON.parse(json) }
    end

    render json: ret
  end

  def fallback
    head :not_found
  end
end
