# coding: utf-8
module Cms::PartFilter::EditCell
  extend ActiveSupport::Concern
  include SS::CrudFilter
  include Cms::NodeFilter::EditCell 
end
