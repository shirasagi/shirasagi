# coding: utf-8
module Kana
  class Initializer
    Cms::PublicFilter.prepend Kana::PublicFilter
  end
end
