if ENV['MONGOID_LOGGER'] == "suppress"
  Mongoid.logger = nil
  Mongo::Logger.logger = nil
elsif ENV['MONGOID_LOGGER'] == "separate"
  path = File.join(Rails.root, 'log', 'mongoid', "#{Rails.env}.log")
  logger = Logger.new File.open(path, "a")
  logger.level = Rails.logger.level
  Mongoid.logger = logger
  Mongo::Logger.logger = logger
end
