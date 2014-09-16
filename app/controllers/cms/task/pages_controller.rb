# coding: utf-8
class Cms::Task::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(opts)
      @task = opts[:task]
      #return unless @cur_site.serve_static_file?

      Cms::Page.site(opts[:site]).public.each do |page|
        next unless page.public_node?
        @task.log page.url if @task
        generate_page page.becomes_with_route
      end
    end

    def generate_with_node(opts)
      @task = opts[:task]
      #return unless @cur_site.serve_static_file?

      Cms::Page.site(opts[:site]).node(opts[:node]).public.each do |page|
        next unless page.public_node?
        @task.log page.url if @task
        generate_page page.becomes_with_route
      end
    end

    def release(opts)
      @task = opts[:task]

      time = Time.now
      cond = [
        { state: "closed", release_date: { "$lte" => time } },
        { state: "public", close_date: { "$lte" => time } }
      ]

      pages = Cms::Page.site(opts[:site]).or(cond).each do |page|
        page = page.becomes_with_route
        @task.log page.url if @task

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
    end

    def remove(opts)
      @task = opts[:task]

      Cms::Page.site(opts[:site]).each do |page|
        @task.log page.url if @task
        Fs.rm_rf page.path
      end
    end
end
