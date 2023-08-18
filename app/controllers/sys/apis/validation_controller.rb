class Sys::Apis::ValidationController < ApplicationController
  include SS::ValidationFilter
  include SS::AjaxFilter
end
