class Cms::Apis::SiteUsagesController < ApplicationController
  include Cms::ApiFilter

  def reload
    @cur_site.reload_usage!
    render
  end
end
