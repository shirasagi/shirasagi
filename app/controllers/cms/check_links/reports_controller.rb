class Cms::CheckLinks::ReportsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::CheckLinks::Report

  navi_view "cms/check_links/main/navi"
  menu_view nil
end
