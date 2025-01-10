RSpec.configuration.after(:suite) do
  # GC.start ensures that temporary file is closed and is deleted.
  ::GC.start
end
