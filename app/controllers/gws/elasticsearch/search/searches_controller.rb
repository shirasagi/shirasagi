class Gws::Elasticsearch::Search::SearchesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Elasticsearch::SearchFilter
end
