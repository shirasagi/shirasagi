require 'spec_helper'

describe Cms::Elasticsearch::Indexer::FeedReleasesJob, dbscope: :example, es: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:file_path) { Rails.root.join('spec/fixtures/ss/shirasagi.pdf') }
  let(:file) { tmp_ss_file(user: user, contents: file_path, binary: true, content_type: 'image/png') }
  let!(:node) { create(:article_node_page, cur_site: site) }
  let!(:page) { create(:article_page, cur_site: site, cur_node: node, file_ids: [file.id], state: "closed") }

  before do
    # cms:es:ingest:init
    ::Cms::Elasticsearch.init_ingest(site: site)
    # cms:es:drop
    ::Cms::Elasticsearch.drop_index(site: site) rescue nil
    # cms:es:create_indexes
    ::Cms::Elasticsearch.create_index(site: site)
  end

  it do
    # 非公開ページを作成した直後
    expect(page.state).to eq 'closed'
    expect(Job::Log.all.count).to eq 0
    expect(Cms::PageRelease.all.count).to eq 1
    Cms::PageRelease.all.first.tap do |page_release|
      expect(page_release.site_id).to eq site.id
      expect(page_release.page_id).to eq page.id
      expect(page_release.filename).to eq page.filename
      expect(page_release.action).to eq "close"
    end
    expect(Cms::PageIndexQueue.all.count).to eq 1
    Cms::PageIndexQueue.all.first.tap do |page_index_queue|
      expect(page_index_queue.site_id).to eq site.id
      expect(page_index_queue.page_id).to eq page.id
      expect(page_index_queue.filename).to eq page.filename
      expect(page_index_queue.action).to eq "close"
    end
    site.elasticsearch_client.search(index: "s#{site.id}", size: 100, q: "*:*").tap do |es_docs|
      expect(es_docs["hits"]["hits"].length).to eq 0
    end

    # cms:es:fee_releases タスクに相当するジョブ（毎時実行する処理）を実行
    expect { described_class.bind(site_id: site).perform_now }.to output(include(site.name)).to_stdout

    expect(Job::Log.all.count).to eq 2
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
    expect(Cms::PageRelease.all.count).to eq 1
    expect(Cms::PageIndexQueue.all.count).to eq 0
    site.elasticsearch_client.search(index: "s#{site.id}", size: 100, q: "*:*").tap do |es_docs|
      expect(es_docs["hits"]["hits"].length).to eq 0
    end

    # publish page and then ...
    page.state = "public"
    page.save!

    # cms/page_release and cms/page_index_queue has a record
    expect(Job::Log.all.count).to eq 2
    expect(Cms::PageRelease.all.count).to eq 2
    Cms::PageRelease.all.order_by(id: -1).first.tap do |page_release|
      expect(page_release.site_id).to eq site.id
      expect(page_release.page_id).to eq page.id
      expect(page_release.filename).to eq page.filename
      expect(page_release.action).to eq "release"
    end
    expect(Cms::PageIndexQueue.all.count).to eq 1
    Cms::PageIndexQueue.all.order_by(id: -1).first.tap do |page_index_queue|
      expect(page_index_queue.site_id).to eq site.id
      expect(page_index_queue.page_id).to eq page.id
      expect(page_index_queue.filename).to eq page.filename
      expect(page_index_queue.action).to eq "release"
    end
    site.elasticsearch_client.search(index: "s#{site.id}", size: 100, q: "*:*").tap do |es_docs|
      expect(es_docs["hits"]["hits"].length).to eq 0
    end

    # cms:es:fee_releases タスクに相当するジョブ（毎時実行する処理）を実行
    expect { described_class.bind(site_id: site).perform_now }.to output(include(site.name)).to_stdout
    # wait for indexing
    ::Cms::Elasticsearch.refresh_index(site: site)

    expect(Job::Log.all.count).to eq 4
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
    expect(Cms::PageRelease.all.count).to eq 2
    expect(Cms::PageIndexQueue.all.count).to eq 0
    site.elasticsearch_client.search(index: "s#{site.id}", size: 100, q: "*:*").tap do |es_docs|
      expect(es_docs["hits"]["hits"].length).to eq 2
      es_docs["hits"]["hits"][0].tap do |es_doc|
        expect(es_doc["_id"]).to eq page.filename
        source = es_doc["_source"]
        expect(source['url']).to eq page.url
      end
      es_docs["hits"]["hits"][1].tap do |es_doc|
        expect(es_doc["_id"]).to eq "file-#{file.id}"
        source = es_doc["_source"]
        expect(source['url']).to eq page.url
      end
    end

    page.state = "closed"
    page.save!

    expect(Job::Log.all.count).to eq 4
    expect(Cms::PageRelease.all.count).to eq 3
    Cms::PageRelease.all.order_by(id: -1).first.tap do |page_release|
      expect(page_release.site_id).to eq site.id
      expect(page_release.page_id).to eq page.id
      expect(page_release.filename).to eq page.filename
      expect(page_release.action).to eq "close"
    end
    expect(Cms::PageIndexQueue.all.count).to eq 1
    Cms::PageIndexQueue.all.order_by(id: -1).first.tap do |page_index_queue|
      expect(page_index_queue.site_id).to eq site.id
      expect(page_index_queue.page_id).to eq page.id
      expect(page_index_queue.filename).to eq page.filename
      expect(page_index_queue.action).to eq "close"
    end
    # ページを非公開にしても、即座に全文検索には反映されない
    site.elasticsearch_client.search(index: "s#{site.id}", size: 100, q: "*:*").tap do |es_docs|
      expect(es_docs["hits"]["hits"].length).to eq 2
    end

    # cms:es:fee_releases タスクに相当するジョブ（毎時実行する処理）を実行
    expect { described_class.bind(site_id: site).perform_now }.to output(include(site.name)).to_stdout
    # wait for indexing
    ::Cms::Elasticsearch.refresh_index(site: site)

    expect(Job::Log.all.count).to eq 6
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
    expect(Cms::PageRelease.all.count).to eq 3
    expect(Cms::PageIndexQueue.all.count).to eq 0
    site.elasticsearch_client.search(index: "s#{site.id}", size: 100, q: "*:*").tap do |es_docs|
      expect(es_docs["hits"]["hits"].length).to eq 0
    end
  end
end
