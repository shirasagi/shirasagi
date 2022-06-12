class Cms::Agents::Tasks::FormDb::ImportController < ApplicationController
  def import_urls
    ::Cms::Site.all.pluck(:id).each_slice(20) do |ids|
      ::Cms::Site.where(:id.in => ids).each do |site|
        import_site_urls(site)
      end
    end

    head :ok
  end

  def import_site_urls(site)
    Cms::FormDb.site(site).import_url_setted.each do |db|
      puts db.name
      db.perform_import
    end
  end

  def import_url
    @db = Cms::FormDb.site(@site).find(@db_id)

    return error('Form: undefined') unless @db.form
    return error('Node: undefined') unless @db.node
    return error('URL: invalid') unless @import_url.to_s.start_with?('http')

    @task.log("[Settings]")
    @task.log("URL: #{@import_url}")
    @task.log("DB: #{@db.name}")
    @task.log("Form: #{@db.form.name}")
    @task.log("Node: #{@db.node.name}")
    @task.log('Primary key: ' + (@db.import_primary_key.presence || '--'))
    @task.log('Title key: ' + (@db.import_page_name || Article::Page.t(:name)))

    begin
      Tempfile.create('import_csv') do |tempfile|
        URI.parse(@import_url).open do |res|
          IO.copy_stream(res, tempfile.path)
          @task.log('[Download] ' + tempfile.size.to_s(:delimited) + ' bytes')
          @task.log('[Import] start') if @task
          @db.import_csv(file: tempfile, task: @task, manually: @import_manually)
          @task.log('[Import] finished')
        end
      end
    rescue => e
      @task.log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    end

    terminate
  end

  def error(message)
    @task.log(message)
    terminate
  end

  def terminate
    @db.save_log(@task.logs.join("\n"))
    @db.trauncate_import_logs

    head :ok
  end
end
