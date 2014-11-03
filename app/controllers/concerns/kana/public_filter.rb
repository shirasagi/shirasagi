module Kana::PublicFilter
  extend ActiveSupport::Concern

  included do
    after_action :render_kana, if: ->{ filters.include?(:kana) }
  end

  private
    def set_request_path_with_kana
      return if @cur_path !~ /^#{SS.config.kana.location}\//
      @cur_path.sub!(/^#{SS.config.kana.location}\//, "/")
      filters << :kana
    end

    def render_kana
      body = response.body

      body = Kana::Convertor.kana_html(body)
      body.sub!(/<body( |>)/m, '<body data-kana="true"\\1')

      response.body = body
    end
end
