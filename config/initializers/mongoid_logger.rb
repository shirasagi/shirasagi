case ENV['MONGOID_LOGGER']
when "suppress"
  Mongoid.logger = nil
  Mongo::Logger.logger = nil
when "separate"
  path = File.join(Rails.root, 'log', 'mongoid', "#{Rails.env}.log")
  logger = Logger.new File.open(path, "a")
  logger.level = Rails.logger.level
  Mongoid.logger = logger
  Mongo::Logger.logger = logger
end
