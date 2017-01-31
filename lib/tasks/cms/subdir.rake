namespace :cms do
  task :set_subdir_url => :environment do
    puts "Please input site_name: site=[site_name]" or exit if ENV['site'].blank?

    @site = SS::Site.where(host: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless @site

    def gsub_path(html)
      html.gsub(/(href|src)=".*?"/) do |m|
        url = m.match(/.*?="(.*?)"/)[1]
        if url =~ /^\/(assets|assets-dev|fs)\//
          m
        elsif url =~ /^#{@site.url}/
          m
        elsif url =~ /^\/(?!\/)/
          m.sub(/="\//, "=\"#{@site.url}")
        else
          m
        end
      end
    end

    def gsub_attrs(model, attrs = nil)
      attrs ||= %w(html upper_html lower_html roop_html)

      ids = model.site(@site).pluck(:id)
      ids.each do |id|
        item = model.find(id) rescue nil
        next unless item

        item = item.becomes_with_route
        attrs = %w(html upper_html lower_html roop_html)
        attrs.each do |attr|
          next unless item.respond_to?(attr) && item.respond_to?("#{attr}=")
          next unless item.send(attr).present?
          item.send("#{attr}=", gsub_path(item.send(attr)))
        end
        item.save!

        puts item.name
      end
    end

    puts "# layouts"
    gsub_attrs(Cms::Layout)

    puts "# parts"
    gsub_attrs(Cms::Part)

    puts "# pages"
    gsub_attrs(Cms::Page)

    puts "# nodes"
    gsub_attrs(Cms::Node)
  end
end
