class Cms::Transaction::Unit::Publisher < Cms::Transaction::Unit::Base
  include Cms::Addon::Transaction::Filename
  include SS::RescueWith

  def type
    "publisher"
  end

  def rescue_p
    proc do |exception|
      exception_backtrace(exception) do |message|
        @task.log message
        Rails.logger.error message
      end
    end
  end

  def execute_main
    rescue_with(rescue_p: rescue_p) do
      each_item do |item|
        publish_page(item)
      end
    end
  end

  def each_item(&block)
    items = Cms::Page.site(site).in(filename: filenames).to_a
    items.each(&block)
  end

  def publish_page(page)
    @task.log page.try(:branch?) ? page.master.full_url : page.full_url
    return if page.public?

    page.cur_site = @site
    page.state = "public"
    page.release_date = nil

    if page.save
      if page.try(:branch?) && page.state == "public"
        page.skip_history_trash = true if page.respond_to?(:skip_history_trash)
        page.destroy
      end
    elsif @task
      @task.log "error: " + page.errors.full_messages.join(', ')
    end
  end
end
