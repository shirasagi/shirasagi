class Cms::PublicController < ApplicationController
  include Cms::PublicFilter
  include Multilingual::PublicFilter
  include Mobile::PublicFilter
  include Kana::PublicFilter

  after_action :put_access_log
  after_action :render_mobile, if: ->{ mobile_path? }
  after_action :render_multilingual, if: ->{ multilingual_path? }

  private
    def protect_csrf?
      false
    end

    def put_access_log
      #
    end
end
