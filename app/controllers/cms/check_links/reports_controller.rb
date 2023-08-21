class Cms::CheckLinks::ReportsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::CheckLinks::Report

  navi_view "cms/main/navi"
  menu_view nil
end
