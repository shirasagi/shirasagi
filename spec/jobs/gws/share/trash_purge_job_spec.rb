require 'spec_helper'

describe Gws::Share::TrashPurgeJob, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:file) { tmpfile { |file| file.write('01234567890') } }
  let(:up) { Fs::UploadedFile.create_from_file(file, basename: 'spec', content_type: 'application/octet-stream') }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:item) { create(:gws_share_file, cur_site: site, cur_user: user, in_file: up, deleted: now - 7.days) }

  describe '#perform' do
    context 'no share files are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.not_to(change { Gws::Share::File.count })

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end
      end
    end

    context 'share files are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: '7.days') }.to \
          change { Gws::Share::File.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end
      end
    end

    context 'when group trash_threshold is 7' do
      before do
        site.set(trash_threshold: 7)
      end

      it do
        expect { described_class.bind(site_id: site).perform_now }.to \
          change { Gws::Share::File.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end
      end
    end
  end
end
