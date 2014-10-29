class Event::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node @node

      @start_date = Date.current.advance(years: -1)
      @close_date = Date.current.advance(years:  1)

      remove_old_pages
      generate_new_pages
    end

  private
    def remove_old_pages
      term = @start_date.advance(years: -1)..@start_date.advance(months: -1)
      term = term.map { |m| sprintf("#{m.year}%02d", m.month) }.uniq
      term.each do |date|
        file = "#{@node.path}/#{date}.html"
        Fs.rm_rf file if  Fs.exists?(file)
      end
    end

    def generate_new_pages
      term = (@start_date..@close_date).map { |m| sprintf("#{m.year}%02d", m.month) }.uniq
      term.each do |date|
        url  = "#{@node.url}/#{date}.html"
        file = "#{@node.path}/#{date}.html"

        if generate_node @node, url: url, file: file
          @task.log url if @task
        end
      end
    end
end
