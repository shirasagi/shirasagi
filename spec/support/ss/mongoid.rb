# mongoid
shared_examples "mongoid#save" do
  it { expect(build(factory).save).to eq true }
end

shared_examples "mongoid#find" do
  it { expect(model.first).not_to eq nil }
  #it { expect(model.all.size).not_to eq 0 }
end

module SS
  module DatabaseCleanerSupport
    def self.extended(obj)
      return unless obj.top_level?

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

module Mongoid
  module Tasks
    module Database
      extend self

      private
        # rewrite logger method.
        def logger
          Rails.logger
        end
    end
  end
end
