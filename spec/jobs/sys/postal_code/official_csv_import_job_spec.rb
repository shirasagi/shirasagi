require 'spec_helper'

describe Sys::PostalCode::OfficialCsvImportJob, type: :job, dbscope: :example do
  context 'When import_from_zip' do
    before do
      described_class.import_from_zip("#{::Rails.root}/spec/fixtures/sys/postal_code.zip")
      @log = Job::Log.first
    end
    it do
      expect(Job::Log.count).to eq 1
      expect(@log.logs).to include(/INFO -- : .* Started Job/)
      expect(@log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end
end
