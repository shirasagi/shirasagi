# mongoid
shared_examples "mongoid#save" do
  it { expect(build(factory).save).to eq true }
end

shared_examples "mongoid#find" do
  it { expect(model.first).not_to eq nil }
  #it { expect(model.all.size).not_to eq 0 }
end

class RSpec::Core::ExampleGroup
  class << self
    alias_method :subclass_original, :subclass
    def subclass(parent, description, args, &example_group_block)
      ret = subclass_original(parent, description, args, &example_group_block)
      is_top_level = parent == RSpec::Core::ExampleGroup
      if is_top_level
        ret.module_exec do
          prepend_before(:context) do
            Rails.logger.debug "#{description}: start database cleaner"
            DatabaseCleaner.start
          end
          after(:context) do
            Rails.logger.debug "#{description}: clean database"
            DatabaseCleaner.clean
          end
        end
      end
      ret
    end
  end
end
