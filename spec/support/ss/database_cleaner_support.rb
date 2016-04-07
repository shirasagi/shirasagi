module SS
  module DatabaseCleanerSupport
    def self.extended(obj)
      dbscope = obj.metadata[:dbscope]
      dbscope ||= RSpec.configuration.default_dbscope

      obj.prepend_before(dbscope) do
        Rails.logger.debug "start database cleaner at #{inspect}"
      end
      obj.after(dbscope) do
        Rails.logger.debug "clean database at #{inspect}"
        ::Mongoid::Clients.default.database.drop
      end

      obj.class_eval do
        define_singleton_method(:clean_database) do
          ::Mongoid::Clients.default.database.drop
        end
        define_method(:clean_database) do
          ::Mongoid::Clients.default.database.drop
        end
      end
    end
  end
end
