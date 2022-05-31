require 'spec_helper'

describe Gws::Elasticsearch::Indexer::BoardTopicJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:file) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }
  let(:category) { create(:gws_board_category, cur_site: site) }

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.save!
  end

  describe '.callback' do
    context 'when model was created' do
      it do
        topic = nil
        perform_enqueued_jobs do
          expectation = expect do
            topic = create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 2
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/gws_board_posts-post-#{topic.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}#post-#{topic.id}"
        end
        es_requests.second.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}#file-#{file.id}"
        end
      end
    end

    context 'when model was updated' do
      let!(:topic) do
        create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            topic.text = unique_id
            topic.file_ids = []
            topic.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 2
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/gws_board_posts-post-#{topic.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}#post-#{topic.id}"
        end
        # file was removed from topic
        es_requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
        end
      end
    end

    context 'when model was destroyed' do
      let!(:topic) do
        create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            topic.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 2
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/gws_board_posts-post-#{topic.id}")
        end
        es_requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
        end
      end
    end

    context 'when model was soft deleted' do
      let!(:topic) do
        create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            topic.deleted = Time.zone.now
            topic.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 2
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/gws_board_posts-post-#{topic.id}")
        end
        es_requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
        end
      end
    end
  end
end
