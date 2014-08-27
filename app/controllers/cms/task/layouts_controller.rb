# coding: utf-8
class Cms::Task::LayoutsController < ApplicationController
  include Cms::ReleaseFilter::Layout

  private
    def set_site
      @cur_site = SS::Site.find_by host: ENV["site"]
    end

  public
    def generate
      set_site
      return puts "Site is unselected." unless @cur_site
      return puts "Site is unselected." unless SS.config.cms.ajax_layout
      return puts "config.cms.serve_static_layouts is false" unless SS.config.cms.serve_static_layouts

      puts "Generate layouts"

      Cms::Layout.site(@cur_site).public.each do |layout|
        puts "  write  #{layout.path.sub(/\.html$/, '.{html,json}')}"
        generate_layout layout
      end
    end

    def generate_file(layout)
      @cur_site = layout.site
      generate_layout layout
    end

    def remove
      set_site
      return puts "Site is unselected." unless @cur_site

      puts "Remove layouts"

      Dir.glob("#{@cur_site.path}/**/*.layout.{html,json}") do |file|
        puts "  remove  #{file}"
        Fs.rm_rf file
      end
    end
end
