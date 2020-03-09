class Opendata::Harvest::ShirasagiScraper
  attr_accessor :url

  def initialize(url, dataset_search_path = "dataset/search")
    @url = url
    @dataset_search_path = dataset_search_path
    @max_pagination = 10_000
  end

  def dataset_search_url
    ::File.join(url, @dataset_search_path, "index.p:page.html")
  end

  def get_dataset_urls
    urls = []
    1.upto(@max_pagination) do |count|
      search_url = dataset_search_url.sub(':page', count.to_s)
      puts search_url

      f = ::URI.open(search_url, read_timeout: 20)
      html = f.read
      #charset = f.charset
      charset = "utf-8"

      doc = Nokogiri::HTML.parse(html, nil, charset)
      links = doc.css('.opendata-search-datasets.pages article h2 > a')
      break if links.blank?

      links.each do |link|
        href = link.attributes["href"]
        next if href.blank?
        urls << ::File.join(url, href.value)
      end
    end
    urls
  end

  def get_dataset(dataset_url)
    dataset = {}

    f = ::URI.open(dataset_url, read_timeout: 20)
    html = f.read
    #charset = f.charset
    charset = "utf-8"

    doc = Nokogiri::HTML.parse(html, nil, charset)
    doc = doc.css(".dataset-tabs").first.parent

    dataset["url"] = dataset_url
    dataset["name"] = doc.css('header h1.name').text.to_s.strip
    dataset["text"] = doc.css('.text').first.text.to_s.strip
    dataset["categories"] = doc.css("nav.categories .category").map { |node| node.text.to_s.strip }
    dataset["areas"] = doc.css("nav.categories .area").map { |node| node.text.to_s.strip }

    dataset["author"] = parse_author_block(doc, "データ作成者") { |dd| dd.text.to_s.strip }
    dataset["created"] = parse_author_block(doc, "作成日時") { |dd| parse_datetime(dd.text.to_s.strip) }
    dataset["updated"] = parse_author_block(doc, "更新日時") { |dd| parse_datetime(dd.text.to_s.strip) }
    dataset["update_plan"] = parse_author_block(doc, "更新頻度") { |dd| dd.text.to_s.strip }

    dataset["resources"] = doc.css(".resources .resource").map do |node|

      dataset["license_title"] ||= doc.css('.license img').first.attributes["alt"].value

      resource = {}
      resource["name"] = node.css(".info .name").text.to_s.strip
      resource["text"] = node.css(".info .text").text.to_s.strip

      data_url = node.css(".icons a.download").first.attributes["data-url"].try(:value)
      if data_url.present?
        resource["url"] = data_url
      else
        href = node.css(".icons a.download").first.attributes["href"].value
        href = ::Addressable::URI.unescape(href)
        resource["url"] = ::File.join(url, href)
      end

      resource["filename"] = ::File.basename(resource["url"])
      resource["format"] = ::File.extname(resource["url"]).downcase.delete(".")

      digits = %w(バイト KB MB GB TB PB)
      bytes, digit = resource["name"].scan(/ ([\d\.]+?)(#{digits.join("|")})\)$/).flatten
      if digits.index(digit)
        resource["display_size"] = (bytes.to_f * (1024 ** digits.index(digit))).to_i
      end
      resource["name"].sub!(/ \(.+?#{bytes}#{digit}\)/, "")

      resource
    end
    dataset["resources"] = dataset["resources"].select { |resource| resource["url"].present? }

    dataset
  end

  private

  def parse_author_block(doc, name)
    doc.css("dl.author dt").each do |dt|
      if dt.text.strip == name
        return yield dt.css("+ dd")
      end
    end
    nil
  end

  def parse_datetime(text)
    datetime_array = text.scan(/(\d+)年(\d+)月(\d+)日 (\d+)時(\d+)分/).flatten
    datetime_array = text.scan(/(\d+)-(\d+)-(\d+)/).flatten if datetime_array.blank?

    datetime = "#{datetime_array[0]}/#{datetime_array[1]}/#{datetime_array[2]}"
    datetime += " #{datetime_array[3]}:#{datetime_array[4]}" if datetime_array[3] && datetime_array[4]

    Time.zone.parse(datetime)
  end
end
