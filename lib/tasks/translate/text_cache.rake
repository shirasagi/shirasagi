namespace :translate do
  task generate_text_caches: :environment do
    puts "Please input site: site=[www]" or exit if ENV['site'].blank?

    @site = ::Cms::Site.where(host: ENV['site']).first
    exit if !@site.translate_enabled?

    target = ENV['lang']
    if @site.translate_targets.index(target)
      targets = [target]
    else
      targets = @site.translate_targets
    end

    puts "# #{@site.name} - #{targets.join(",")}"

    # pages
    puts "# pages"
    count = 0

    pages = Cms::Page.site(@site).and_public
    ids = pages.pluck(:id)
    ids.each_with_index do |id, idx|
      page = Cms::Page.site(@site).and_public.where(id: id).first
      next unless page

      targets.each do |target|
        next if !Fs.exists?(page.path)

        puts "#{idx + 1} #{target} : #{page.name} #{page.path.sub(@site.path, "")}"
        count += 1

        html = Fs.read(page.path)
        converter = Translate::Convertor.new(@site, @site.translate_source, target)
        converter.convert(html)
      end
    end
    puts "translated #{count} pages"

    # nodes
    puts "# nodes"
    count = 0

    nodes = Cms::Node.site(@site).and_public
    ids = nodes.pluck(:id)
    ids.each_with_index do |id, idx|
      node = Cms::Node.site(@site).and_public.where(id: id).first
      next unless node
      next unless node.public?
      next unless node.public_node?

      paths = ["/index.html", "/index.*.html"]
      if node.route == "event/page"
        paths = ["/index.html", "/*/index.html", "/*/table.html"]
      elsif node.route == "facility/search"
        paths = ["/index.html", "/map-all.html"]
      end
      paths = paths.map { |path| node.path + path }

      Dir.glob(paths).each do |path|
        targets.each do |target|
          puts "#{idx + 1} #{target} : #{node.name} #{path.sub(@site.path, "")}"
          count += 1

          html = Fs.read(path)
          converter = Translate::Convertor.new(@site, @site.translate_source, target)
          converter.convert(html)
        end
      end
    end
    puts "translated #{count} nodes"
  end

  task remove_text_caches: :environment do
    puts "Please input site: site=[www]" or exit if ENV['site'].blank?

    target = ENV['lang']
    @site = ::Cms::Site.where(host: ENV['site']).first
    @items = Translate::TextCache.site(@site)

    if target.present?
      @items = @items.where(target: target)
      puts "# #{@site.name} - #{target}"
    else
      puts "# #{@site.name}"
    end

    @items.destroy_all

    puts "destroy text_caches"
  end
end
