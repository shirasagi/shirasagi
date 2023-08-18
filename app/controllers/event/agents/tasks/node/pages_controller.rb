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

  def each_month(from, to)
    i = from
    while i <= to
      yield i
      i += 1.month
    end
  end

  def remove_old_pages
    each_month(@start_date.advance(years: -1), @close_date) do |m|
      date = sprintf("#{m.year}%02d", m.month)

      file = "#{@node.path}/#{date}.html"
      Fs.rm_rf(file) if Fs.exist?(file)

      event_display_options.each do |display|
        base = "#{@node.path}/#{date}/#{display}"
        file = "#{base}.html"
        Fs.rm_rf(file) if Fs.exist?(file)
        file = "#{base}.ics"
        Fs.rm_rf(file) if Fs.exist?(file)
      end
    end
  end

  def generate_new_pages
    each_month(@start_date, @close_date) do |m|
      date = sprintf("#{m.year}%02d", m.month)
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
