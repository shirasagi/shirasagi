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
        ret = Mobile::Converter.new(@item.try(:title).try(:content) || '')
        ret.remove_other_namespace_tags!
        ret.remove_comments!
        ret.remove_cdata_sections!
        ret.strip!
        ret
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

  def self.parse(url)
    rss = ::RSS::Parser.parse(url, false)

    case rss
    when ::RSS::Atom::Feed
      ::Rss::Wrappers::Atom.wrap(rss)
    when ::RSS::Rss
      ::Rss::Wrappers::Rss.wrap(rss)
    when ::RSS::RDF
      ::Rss::Wrappers::RDF.wrap(rss)
    end
  end
end
