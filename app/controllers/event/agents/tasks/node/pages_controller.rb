class Event::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node
  include Event::GeneratorFilter::Ical

  def generate
    written = generate_node @node
    if written
      @task.log "#{@node.url}index.html" if @task
    end

    # initialize context before generating rss
    init_context
    if generate_node_ical @node
      @task.log "#{@node.url}index.ics" if @task
    end

    @start_date = Time.zone.today.advance(years: -1)
    @close_date = Time.zone.today.advance(years: 1)

    remove_old_pages
    generate_new_pages

    written
  end

  private

  def event_display_options
    %w(index list table)
  end

  def remove_old_pages
    term = @start_date.advance(years: -1)..@start_date.advance(months: -1)
    term = term.map { |m| sprintf("#{m.year}%02d", m.month) }.uniq
    term.each do |date|
      file = "#{@node.path}/#{date}.html"
      Fs.rm_rf(file) if Fs.exists?(file)

      event_display_options.each do |display|
        base = "#{@node.path}/#{date}/#{display}"
        file = "#{base}.html"
        Fs.rm_rf(file) if Fs.exists?(file)
        file = "#{base}.ics"
        Fs.rm_rf(file) if Fs.exists?(file)
      end
    end
  end

  def generate_new_pages
    term = (@start_date..@close_date).map { |m| sprintf("#{m.year}%02d", m.month) }.uniq
    term.each do |date|
      event_display_options.each do |display|
        url  = "#{@node.url}#{date}/#{display}.html"
        file = "#{@node.path}/#{date}/#{display}.html"

        init_context
        if generate_node(@node, url: url, file: file)
          @task.log url if @task
        end
      end
    end
  end
end
