class Cms::ImportFilesJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(opts = {})
    Cms::ImportJobFile.where(:import_date.lte => Time.zone.now).each do |item|
      begin
        if item.node
          put_log("import in #{item.node.name}(#{item.node.filename})")
          item.import
          item.import_logs.each { |log| put_log(log) }
        else
          put_log("error not found node (#{item.node_id})")
        end
        put_log(" ")
      ensure
        item.destroy
      end
    end
  end
end
