class Cms::Agents::Tasks::FormDb::ImportController < ApplicationController
  def import_url
    @db = Cms::FormDb.site(@site).find(@db_id)

    return error('Form: undefined') unless @db.form
    return error('Node: undefined') unless @db.node
    return error('URL: invalid') unless @import_url.to_s.start_with?('http')

    @task.log("DB: #{@db.name}")
    @task.log("Form: #{@db.form.name}")
    @task.log("Node: #{@db.node.name}")
    @task.log("URL: #{@import_url}")

    begin
      Tempfile.create('import_csv') do |tempfile|
        @task.log("Download: start")

        URI.parse(@import_url).open do |res|
          IO.copy_stream(res, tempfile.path)
          @task.log("Download: success")
          @task.log("Import: start")

          @db.import_csv(file: tempfile, task: @task)
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
