module Kana::PublicFilter
  extend ActiveSupport::Concern

  included do
    Cms::PublicFilter.filter :set_path_with_kana
    after_action :render_kana, if: ->{ @filter == :kana }
  end

  private
    def set_path_with_kana
      return if @cur_path !~ /^#{SS.config.kana.location}\//
      @cur_path.sub!(/^#{SS.config.kana.location}\//, "/")
      @filter = :kana
    end

    def render_kana
      body = response.body

      body = Kana::Convertor.kana_html(body)
      body.sub!(/<body( |>)/m, '<body data-kana="true"\\1')

      response.body = body
    end
end
