# coding: utf-8
class Cms::Task::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page
  
  private
    def set_site
      @cur_site = SS::Site.where(host: ENV["site"]).first
    end
    
  public
    def release
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
    
    def generate
      set_site
      return puts "Site is unselected." unless @cur_site
      return puts "config.cms.serve_static_pages is false" unless SS.config.cms.serve_static_pages
      
      puts "Generate pages"
      
      Cms::Page.site(@cur_site).public.each do |page|
        puts "write  #{page.url}"
        generate_page page
      end
    end
    
    def generate_file(page)
      @cur_site = page.site
      generate_page page
    end
    
    def remove
      set_site
      return puts "Site is unselected." unless @cur_site
      
      puts "Remove pages"
      
      Cms::Page.site(@cur_site).each do |page|
        puts "remove  #{page.url}"
        Fs.rm_rf page.path
      end
    end
end
