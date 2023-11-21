class Cms::Agents::Tasks::ImportFilesController < ApplicationController
  def import
    Cms::ImportJobFile.site(@site).where(:import_date.lte => Time.zone.now, job_wait: nil).each do |item|
      begin
        import_one(item)
      ensure
        item.destroy
        @task.log(" ")
      end
    end

    head :ok
  end

  private

  def import_one(item)
    unless item.root_node
      @task.log("error not found node (#{item.node_id})")
      return
    end

    @task.tagged("#{item.root_node.name}(#{item.root_node.filename})") do
      @task.log("start importing")
      item.import
      item.import_logs.each { |log| @task.log(log) }
    rescue => e
      SS.log_error(e, recursive: true)
    end
  end
end
