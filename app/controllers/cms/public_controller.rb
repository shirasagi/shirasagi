class Cms::PublicController < ApplicationController
  include Cms::PublicFilter

  after_action :put_access_log
  after_action :render_mobile, if: ->{ mobile_path? }

  private
    def put_access_log
      #
    end
end
