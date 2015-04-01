module SS
  module DatabaseCleanerSupport
    def self.extended(obj)
      dbscope = obj.metadata[:dbscope]
      dbscope ||= RSpec.configuration.default_dbscope

      obj.prepend_before(dbscope) do
        Rails.logger.debug "start database cleaner at #{inspect}"
        DatabaseCleaner.start
      end
      obj.after(dbscope) do
        Rails.logger.debug "clean database at #{inspect}"
        DatabaseCleaner.clean
      end
    end
  end
end
