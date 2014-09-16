# coding: utf-8
class Cms::Task::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(opts)
      return puts "config.cms.serve_static_pages is false" unless SS.config.cms.serve_static_pages

      cond = opts[:site] ? { host: opts[:site] } : {}
      SS::Site.where(cond).each do |site|
        @task.log "#{site.name}"
        @cur_site = site
        task_cond = { name: "cms:page:generate", site_id: @cur_site.id, node_id: nil }
        page_cond = {}

        if opts[:node]
          @cur_node = Cms::Node.site(site).find_by filename: opts[:node]
          task_cond[:node_id]  = @cur_node.id
          page_cond[:filename] = /^#{@cur_node.filename}\//
        end

        @task = Cms::Task.find_or_create_by task_cond
        @task.run do
          Cms::Page.site(@cur_site).where(page_cond).public.each do |page|
            next unless page.public_node?
            @task.log "#{page.url}"
            generate_page page.becomes_with_route
          end
        end
      end
    end

    def generate_file(page)
      @cur_site = page.site
      generate_page page
    end

    def remove(opts)
      puts "# start cms:page:remove.."
      SS::Site.where(opts[:site] ? { host: opts[:site] } : {}).each do |site|
        Cms::Page.site(site).each do |page|
          puts page.url
          Fs.rm_rf page.path
        end
      end
      puts "# end."
    end

    def release(opts)
      puts "# start cms:page:release.."

      time = Time.now
      cond = []
      cond << { state: "closed", release_date: { "$lte" => time } }
      cond << { state: "public", close_date: { "$lte" => time } }

      pages = Cms::Page.or(cond).each do |page|
        puts page.full_url
        page = page.becomes_with_route

        if page.public?
          page.state = "closed"
          page.close_date = nil
        else
          page.state = "public"
          page.release_date = nil
        end

        next if page.save
        puts "error: " + page.errors.full_messages.join(', ')
      end

      puts "# end."
    end
end
