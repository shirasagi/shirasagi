class Cms::PublicController < ApplicationController
  include Cms::PublicFilter

  after_action :put_access_log

  private
    def put_access_log
      #
    end
end
