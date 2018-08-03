class Event::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node

    @start_date = Time.zone.today.advance(years: -1)
    @close_date = Time.zone.today.advance(years: 1)

    remove_old_pages
    generate_new_pages
  end

  private

  def event_display_options
    ['', '_list', '_table']
  end

  def remove_old_pages
    term = @start_date.advance(years: -1)..@start_date.advance(months: -1)
    term = term.map { |m| sprintf("#{m.year}%02d", m.month) }.uniq
    term.each do |date|
      event_display_options.each do |display|
        file = "#{@node.path}/#{date}#{display}.html"
        Fs.rm_rf file if Fs.exists?(file)
      end
    end
  end

  def generate_new_pages
    term = (@start_date..@close_date).map { |m| sprintf("#{m.year}%02d", m.month) }.uniq
    term.each do |date|
      event_display_options.each do |display|
        url  = "#{@node.url}#{date}#{display}.html"
        file = "#{@node.path}/#{date}#{display}.html"

        if generate_node @node, url: url, file: file
          @task.log url if @task
        end
      end
    end
  end
end
