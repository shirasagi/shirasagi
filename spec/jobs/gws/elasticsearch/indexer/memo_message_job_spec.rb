require 'spec_helper'

describe Gws::Elasticsearch::Indexer::MemoMessageJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:recipient) { create(:gws_user) }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:file) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }
  let(:category) { create(:gws_board_category, cur_site: site) }

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.save!

    # gws:es:ingest:init
    ::Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    ::Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    ::Gws::Elasticsearch.create_index(site: site)
  end

  describe '#index' do
    let!(:recipient0) { create(:gws_user) }
    let!(:recipient1) { create(:gws_user) }
    let!(:recipient2) { create(:gws_user) }
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user, state: "public",
        in_to_members: [ recipient0.id ], in_cc_members: [ recipient1.id ], in_bcc_members: [ recipient2.id ],
        file_ids: [file.id]
      )
    end

    context "when message is sent" do
      it do
        job = described_class.bind(site_id: site)
        job.perform_now(action: 'index', id: message.id.to_s)

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.user_long_name
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to eq [ recipient0.id, recipient1.id, recipient2.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#file-#{file.id}"
            expect(source['name']).to eq file.name
            expect(source['file']['extname']).to eq file.extname.upcase
            expect(source['file']['size']).to eq file.size
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to eq [ recipient0.id, recipient1.id, recipient2.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end

    context "when recipient in to deletes message" do
      before do
        message.destroy_from_member(recipient0)
      end

      it do
        job = described_class.bind(site_id: site)
        job.perform_now(action: 'index', id: message.id.to_s)

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.user_long_name
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to eq [ recipient1.id, recipient2.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#file-#{file.id}"
            expect(source['name']).to eq file.name
            expect(source['file']['extname']).to eq file.extname.upcase
            expect(source['file']['size']).to eq file.size
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to eq [ recipient1.id, recipient2.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end

    context "when recipient in bcc deletes message" do
      before do
        message.destroy_from_member(recipient2)
      end

      it do
        job = described_class.bind(site_id: site)
        job.perform_now(action: 'index', id: message.id.to_s)

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.user_long_name
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to eq [ recipient0.id, recipient1.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#file-#{file.id}"
            expect(source['name']).to eq file.name
            expect(source['file']['extname']).to eq file.extname.upcase
            expect(source['file']['size']).to eq file.size
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to eq [ recipient0.id, recipient1.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end

    context "when all recipients delete message" do
      before do
        message.destroy_from_member(recipient0)
        message.destroy_from_member(recipient1)
        message.destroy_from_member(recipient2)
      end

      it do
        job = described_class.bind(site_id: site)
        job.perform_now(action: 'index', id: message.id.to_s)

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.user_long_name
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to be_blank
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#file-#{file.id}"
            expect(source['name']).to eq file.name
            expect(source['file']['extname']).to eq file.extname.upcase
            expect(source['file']['size']).to eq file.size
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_ids']).to eq [ message.user_id ]
            expect(source['readable_member_ids']).to be_blank
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end

    context "when sender deletes message" do
      before do
        message.destroy_from_sent
      end

      it do
        job = described_class.bind(site_id: site)
        job.perform_now(action: 'index', id: message.id.to_s)

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.user_long_name
            expect(source['user_ids']).to be_blank
            expect(source['readable_member_ids']).to eq [ recipient0.id, recipient1.id, recipient2.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#file-#{file.id}"
            expect(source['name']).to eq file.name
            expect(source['file']['extname']).to eq file.extname.upcase
            expect(source['file']['size']).to eq file.size
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_ids']).to be_blank
            expect(source['readable_member_ids']).to eq [ recipient0.id, recipient1.id, recipient2.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end
  end

  describe '#delete' do
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user,
        user_settings: [{ 'user_id' => recipient.id.to_s, 'path' => 'INBOX' }], member_ids: [recipient.id],
        file_ids: [file.id]
      )
    end

    it do
      job = described_class.bind(site_id: site)
      job.perform_now(action: 'delete', id: message.id.to_s, remove_file_ids: message.file_ids)

      # wait for indexing
      ::Gws::Elasticsearch.refresh_index(site: site)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 0
      end
    end
  end

  describe '.callback on gws/memo/message' do
    context 'when model was created' do
      it do
        expectation = expect do
          create(
            :gws_memo_message, cur_site: site, cur_user: user, in_to_members: [ recipient.id ], file_ids: [file.id]
          )
        end
        expectation.to change { enqueued_jobs.size }.by(1)
      end
    end

    context 'when model was updated' do
      let!(:message) do
        create(
          :gws_memo_message, cur_site: site, cur_user: user, in_to_members: [ recipient.id ], file_ids: [file.id]
        )
      end

      it do
        expectation = expect do
          message.text = unique_id
          message.file_ids = []
          message.save!
        end
        expectation.to change { enqueued_jobs.size }.by(1)
      end
    end

    context 'when model was destroyed' do
      let!(:message) do
        create(
          :gws_memo_message, cur_site: site, cur_user: user, in_to_members: [ recipient.id ], file_ids: [file.id]
        )
      end

      it do
        expectation = expect do
          message.destroy
        end
        expectation.to change { enqueued_jobs.size }.by(1)
      end
    end
  end

  describe '.callback on gws/memo/list_message' do
    let!(:group) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:list) do
      create(:gws_memo_list, cur_site: site, member_ids: [user.id, recipient.id], user_ids: [user.id], group_ids: [group.id])
    end

    context 'when model was created' do
      it do
        message = nil
        perform_enqueued_jobs do
          message = create(
            :gws_memo_list_message, cur_site: site, cur_user: user, list: list, state: 'public', file_ids: [file.id]
          )
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.from_member_name
            expect(source['user_ids']).to eq list.user_ids
            expect(source['group_ids']).to eq list.group_ids
            expect(source['custom_group_ids']).to eq list.custom_group_ids
            expect(source['permission_level']).to eq list.permission_level
            expect(source['readable_member_ids']).to eq [ user.id, recipient.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#file-#{file.id}"
            expect(source['name']).to eq file.name
            expect(source['file']['extname']).to eq file.extname.upcase
            expect(source['file']['size']).to eq file.size
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_ids']).to eq list.user_ids
            expect(source['group_ids']).to eq list.group_ids
            expect(source['custom_group_ids']).to eq list.custom_group_ids
            expect(source['permission_level']).to eq list.permission_level
            expect(source['readable_member_ids']).to eq [ user.id, recipient.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end

    context 'when model was updated' do
      let!(:message) do
        create(
          :gws_memo_list_message, cur_site: site, cur_user: user, list: list, state: 'public', file_ids: [file.id]
        )
      end

      it do
        perform_enqueued_jobs do
          message.text = unique_id
          message.file_ids = []
          message.save!
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 1
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.from_member_name
            expect(source['user_ids']).to eq list.user_ids
            expect(source['group_ids']).to eq list.group_ids
            expect(source['custom_group_ids']).to eq list.custom_group_ids
            expect(source['permission_level']).to eq list.permission_level
            expect(source['readable_member_ids']).to eq [ user.id, recipient.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end

    context 'when model was updated as gws/memo/message' do
      let!(:list_message) do
        create(
          :gws_memo_list_message, cur_site: site, cur_user: user, list: list, state: 'public', file_ids: [file.id]
        )
      end
      let!(:message) do
        Gws::Memo::Message.find(list_message.id)
      end

      it do
        perform_enqueued_jobs do
          message.destroy_from_member(user)
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_memo_messages-message-#{message.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#message-#{message.id}"
            expect(source['name']).to eq message.subject
            expect(source['mode']).to eq message.format
            expect(source['text']).to eq message.text
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_name']).to eq message.from_member_name
            expect(source['user_ids']).to eq list.user_ids
            expect(source['group_ids']).to eq list.group_ids
            expect(source['custom_group_ids']).to eq list.custom_group_ids
            expect(source['permission_level']).to eq list.permission_level
            expect(source['readable_member_ids']).to eq [ recipient.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/memo/messages/REDIRECT/#{message.id}#file-#{file.id}"
            expect(source['name']).to eq file.name
            expect(source['file']['extname']).to eq file.extname.upcase
            expect(source['file']['size']).to eq file.size
            expect(source['released']).to eq message.send_date.iso8601
            expect(source['state']).to eq message.state
            expect(source['user_ids']).to eq list.user_ids
            expect(source['group_ids']).to eq list.group_ids
            expect(source['custom_group_ids']).to eq list.custom_group_ids
            expect(source['permission_level']).to eq list.permission_level
            expect(source['readable_member_ids']).to eq [ recipient.id ]
            expect(source['updated']).to be_present
            expect(source['created']).to be_present
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:message) do
        create(
          :gws_memo_list_message, cur_site: site, cur_user: user, list: list, state: 'public', file_ids: [file.id]
        )
      end

      it do
        perform_enqueued_jobs do
          message.destroy
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
        end
      end
    end

    context 'when model was destroyed as gws/memo/message' do
      let!(:list_message) do
        create(
          :gws_memo_list_message, cur_site: site, cur_user: user, list: list, state: 'public', file_ids: [file.id]
        )
      end
      let!(:message) do
        Gws::Memo::Message.find(list_message.id)
      end

      it do
        perform_enqueued_jobs do
          message.destroy
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
        end
      end
    end
  end
end
