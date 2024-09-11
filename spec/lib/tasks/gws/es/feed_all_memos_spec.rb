require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example, es: true do
  before do
    @save = {}
    ENV.each do |key, value|
      @save[key.dup] = value.dup
    end

    # gws:es:ingest:init
    ::Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    ::Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    ::Gws::Elasticsearch.create_index(site: site)
  end

  after do
    ENV.clear
    @save.each do |key, value|
      ENV[key] = value
    end
  end

  describe ".feed_all_memos" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:recipient0) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:recipient1) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:recipient2) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:message1) do
      file = tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
      create(
        :gws_memo_message, cur_site: site, cur_user: user, state: "public",
        in_to_members: [ recipient0.id ], in_cc_members: [ recipient1.id ], in_bcc_members: [ recipient2.id ],
        file_ids: [file.id]
      )
    end
    let!(:message2) do
      file = tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
      create(
        :gws_memo_message, cur_site: site, cur_user: user, state: "public",
        in_to_members: [ recipient0.id ], in_cc_members: [ recipient1.id ], in_bcc_members: [ recipient2.id ],
        file_ids: [file.id]
      )
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_memos }.to output(include("gws/memo/message\n")).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 4
      end
    end
  end
end
