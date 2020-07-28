require 'spec_helper'

describe Sys::PrefectureCode::ImportJob, type: :job, dbscope: :example do
  describe '#perform' do
    let(:csv) { "#{Rails.root}/spec/fixtures/sys/prefecture_code_tokushima.csv" }

    it do
      file = Fs::UploadedFile.create_from_file(csv)
      #expect(Webmail::RoleImportJob.valid_csv?(file)).to be_truthy

      temp_file = SS::TempFile.new
      temp_file.in_file = file
      temp_file.save!

      job = Sys::PrefectureCode::ImportJob.bind(user_id: ss_user)
      job.perform_now(temp_file.id)

      Job::Log.first.tap do |log|
        expect(log.attributes[:logs]).to be_empty
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
      expect(Job::Log.count).to eq 1
    end
  end
end
