require 'spec_helper'

describe Gws::CompressJob, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:file) { create :gws_share_file }
  let(:files) { Gws::Share::File.all }

  describe '#perform' do
    context 'normal notify' do
      it do
        zip = Gws::Compressor.new(user, items: files)
        zip.url = sns_download_job_files_url(host: 'localhost', user: zip.user, filename: zip.filename)

        job = Gws::CompressJob.bind(site_id: site, user_id: user)
        job.perform_now(zip.serialize)

        Job::Log.first.tap do |log|
          expect(log.attributes[:logs]).to be_empty
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
        expect(Job::Log.count).to eq 1

        SS::Notification.first.tap do |notice|
          expect(notice.subject).to include I18n.t('gws/share.mailers.compressed.subject')
        end
        expect(SS::Notification.count).to eq 1
      end
    end
  end
end
