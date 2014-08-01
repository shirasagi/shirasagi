# coding: utf-8
module Opendata
  class Initializer
    Cms::Node.plugin "opendata/dataset"
    Cms::Node.plugin "opendata/app"
    Cms::Node.plugin "opendata/idea"
  end
end
