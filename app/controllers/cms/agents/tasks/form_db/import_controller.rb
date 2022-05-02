class Cms::Agents::Tasks::FormDb::ImportController < ApplicationController
  def import_url
    @task.log("Import pages")
    @task.log("node: #{@node.name}")

    @db = Cms::FormDb.site(@site).find(@db_id)
    @form = @db.form
    @task.log("form: #{@form.name}")

    Tempfile.create('import_csv') do |tempfile|
      @task.log("templfile: #{tempfile.path}")
      @task.log("download: #{@import_url}")

      URI.open(@import_url) do |res|
        IO.copy_stream(res, tempfile.path)
        @task.log("download: success")

        @db.import_csv(file: tempfile, task: @task)
      end
    end

    @db.save_log(@task.logs.join("\n"))

    head :ok
  end
end
