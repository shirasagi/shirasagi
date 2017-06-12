require 'spec_helper'

describe Sys::PostalCode::ImportJob, type: :job, dbscope: :example do
  context do
    before do
      described_class.import_from_zip("#{::Rails.root}/spec/fixtures/sys/postal_code.zip")
      @log = Job::Log.first
    end
    it { expect(Job::Log.count).to eq 1 }
    it { expect(@log.logs).to include(include("INFO -- : Started Job")) }
    it { expect(@log.logs).to include(include("INFO -- : Completed Job")) }
  end
end
