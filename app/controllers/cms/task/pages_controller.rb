# coding: utf-8
class Cms::Task::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(opts)
      return puts "config.cms.serve_static_pages is false" unless SS.config.cms.serve_static_pages

      SS::Site.where(opts[:site] ? { host: opts[:site] } : {}).each do |site|
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
            generate_page page
          end
        end
      end
    end

    def generate_file(page)
      @cur_site = page.site
      generate_page page
    end

    def remove(opts)
      puts "start remove pages.."
      SS::Site.where(opts[:site] ? { host: opts[:site] } : {}).each do |site|
        Cms::Page.site(site).each do |page|
          puts page.url
          Fs.rm_rf page.path
        end
      end
      puts "end."
    end

    def release(opts)
      time = Time.now

      cond  = { state: "closed", release_date: { "$lte" => time } }
      pages = Cms::Page.where(cond)
      puts "release #{pages.size} pages." if pages.size > 0

      pages.each do |page|
        page = page.becomes_with_route
        page.state = "public"
        page.release_date = nil
        if !page.save
          puts "  #{page.filename}: #{page.errors.full_messages.join(', ')}"
        end
      end

      cond  = { state: "public", close_date: { "$lte" => time } }
      pages = Cms::Page.where(cond)
      puts "close   #{pages.size} pages." if pages.size > 0

      pages.each do |page|
        page = page.becomes_with_route
        page.state = "closed"
        page.close_date = nil
        if !page.save
          puts "  #{page.filename}: #{page.errors.full_messages.join(', ')}"
        end
      end
    end
end
