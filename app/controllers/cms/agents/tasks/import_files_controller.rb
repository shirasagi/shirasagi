class Cms::Agents::Tasks::ImportFilesController < ApplicationController
  def import
    Cms::ImportJobFile.site(@site).where(:import_date.lte => Time.zone.now, job_wait: nil).each do |item|
      begin
        if item.root_node
          @task.log("import in #{item.root_node.name}(#{item.root_node.filename})")
          item.import
          item.import_logs.each { |log| @task.log(log) }
        else
          @task.log("error not found node (#{item.node_id})")
        end
        @task.log(" ")
      ensure
        item.destroy
      end
    end

    head :ok
  end
end
