require 'active_support/deprecation/reporting'
require 'sass/importers'
require 'sprockets/file_reader'
require 'sprockets/erb_processor'
require 'sprockets/processor_utils'

class Fs::GridFs::CompassImporter < Sass::Importers::Base
  attr_reader :root

  def initialize(root)
    @root = root
  end

  def find(uri, options)
    filename = find_file(uri)
    if filename
      return Sass::Engine.new(::Fs.read(filename), options.merge(filename: filename))
    end

    nil
  end

  def find_relative(uri, base, options)
    nil
  end

  def to_s
    self.class.name
  end

  def hash
    "#{self.class.name}:#{@root}".hash
  end

  def eql?(other)
    other.class == self.class && other.root == self.root
  end

  def mtime(uri, options)
    filename = find_file(uri)
    if filename
      return ::Fs.stat(filename).mtime
    end

    nil
  end

  def key(uri, options={})
    [ self.class.name + ":#{@root}:" + File.dirname(File.expand_path(uri)), File.basename(uri) ]
  end

  def public_url(*args)
    nil
  end

  private

    def find_file(uri)
      %w(.css .scss).each do |suffix|
        filename = "#{@root}/_#{uri}#{suffix}"
        if ::Fs.exists?(filename)
          return filename
        end
      end

      nil
    end
end
