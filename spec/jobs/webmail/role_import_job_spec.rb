require 'spec_helper'

describe Webmail::RoleImportJob, dbscope: :example do
  describe '#perform' do
    let!(:role1) { create(:webmail_role_admin) }
    let!(:role2) { create(:webmail_role_user) }
    let(:csv) { "#{Rails.root}/spec/fixtures/webmail/roles.csv" }
    let(:png) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

    it do
      file = Fs::UploadedFile.create_from_file(png)
      expect(Webmail::RoleImportJob.valid_csv?(file)).to be_falsey

      file = Fs::UploadedFile.create_from_file(csv)
      expect(Webmail::RoleImportJob.valid_csv?(file)).to be_truthy

      temp_file = SS::TempFile.new
      temp_file.in_file = file
      temp_file.save!

      job = Webmail::RoleImportJob.bind(user_id: ss_user)
      job.perform_now(temp_file.id)

      Job::Log.first.tap do |log|
        expect(log.attributes[:logs]).to be_empty
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(match(/2行目:.*インポートしました。/))
        expect(log.logs).to include(match(/3行目:.*空白のため無視します。/))
        expect(log.logs).to include(match(/4行目:.*見つからないため無視します。/))
        expect(log.logs).to include(match(/5行目:.*インポートしました。/))
        expect(log.logs).to include(match(/6行目:.*エラーが発生しました。/))
      end
      expect(Job::Log.count).to eq 1
    end
  end
end
