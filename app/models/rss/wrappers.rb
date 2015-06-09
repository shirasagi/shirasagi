module Rss::Wrappers
  module Items
    class Atom
      def initialize(item)
        @item = item
      end

      def self.wrap(item)
        new(item)
      end

      def name
        @item.try(:title).try(:content)
      end

      def link
        link = @item.links.find { |link| link.rel == 'alternate' }
        link ||= @item.link
        link.try(:href)
      end

      def html
        @item.try(:content).try(:content) || @item.try(:summary).try(:content)
      end

      def released
        @item.try(:updated).try(:content) || @item.try(:published).try(:content) || Time.zone.now
      end
    end

    class Rss
      def initialize(item)
        @item = item
      end

      def self.wrap(item)
        new(item)
      end

      def name
        @item.title
      end

      def link
        @item.link
      end

      def html
        @item.description
      end

      def released
        @item.pubDate || @item.date || Time.zone.now
      end
    end

    class RDF
      def initialize(item)
        @item = item
      end

      def self.wrap(item)
        new(item)
      end

      def name
        @item.title
      end

      def link
        @item.link
      end

      def html
        @item.description
      end

      def released
        @item.date || Time.zone.now
      end
    end
  end

  class Atom
    def initialize(rss)
      @rss = rss
    end

    def self.wrap(rss)
      new(rss)
    end

    def each(&block)
      @rss.items.each do |item|
        yield ::Rss::Wrappers::Items::Atom.wrap(item)
      end
    end
  end

  class Rss
    def initialize(rss)
      @rss = rss
    end

    def self.wrap(rss)
      new(rss)
    end

    def each(&block)
      @rss.items.each do |item|
        yield ::Rss::Wrappers::Items::Rss.wrap(item)
      end
    end

    def wrap_item(item)

    end
  end

  class RDF
    def initialize(rss)
      @rss = rss
    end

    def self.wrap(rss)
      new(rss)
    end

    def each(&block)
      @rss.items.each do |item|
        yield ::Rss::Wrappers::Items::RDF.wrap(item)
      end
    end
  end
end