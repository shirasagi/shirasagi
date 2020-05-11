require 'zlib'

class Cms::Michecker::Accessibility
  include ActiveModel::Model

  attr_accessor :items

  class << self
    def load(filename)
      items = []
      ::Zlib::GzipReader.open(filename) do |gz|
        gz.each_line do |line|
          items.push(OpenStruct.new(::JSON.parse(line)))
        end
      end

      new(items: items)
    end
  end
end
