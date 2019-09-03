require 'spec_helper'

describe Cms::Elasticsearch::Indexer::PageReleaseJob, dbscope: :example, tmpdir: true, es: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create(:article_node_page, cur_site: site) }
  let(:page) { create(:article_page, cur_site: site, cur_node: node, released: Time.zone.now, file_ids: [file.id]) }
  let(:file) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:requests) { [] }

  before do
    stub_request(:any, /#{::Regexp.escape(site.elasticsearch_hosts.first)}/).to_return do |request|
      requests << request.as_json.dup
      { body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
    end
  end

  describe 'feed_releases' do
    it do
      # release

      expect(page.status).to eq 'public'

      releases = Cms::PageRelease.all.order_by(created: -1).entries
      releases.first.tap do |release|
        expect(release.state).to eq 'active'
        expect(release.action).to eq 'release'
        expect(release.es_state).to eq nil
      end
      expect(releases.size).to eq 1

      # index / release

      items = Cms::PageRelease.site(site).active.unindexed.order_by(created: 1)
      items.each do |item|
        job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
        job.perform_now(action: 'index', id: item.page_id.to_s, release_id: item.id.to_s)
      end
      expect(Job::Log.first.logs).to include(include("INFO -- : Completed Job"))
      expect(Job::Log.count).to eq 1

      releases = Cms::PageRelease.all.order_by(created: -1).entries
      releases.first.tap do |release|
        expect(release.state).to eq 'active'
        expect(release.action).to eq 'release'
        expect(release.es_state).to eq 'indexed'
      end
      expect(releases.size).to eq 1

      # close

      page.update_attributes(state: 'closed')

      releases = Cms::PageRelease.all.order_by(created: -1).entries
      releases.first.tap do |release|
        expect(release.state).to eq 'active'
        expect(release.action).to eq 'close'
        expect(release.es_state).to eq nil
      end
      expect(releases.size).to eq 2

      # index / close

      items = Cms::PageRelease.site(site).active.unindexed.order_by(created: 1)
      items.each do |item|
        job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
        job.perform_now(action: 'index', id: item.page_id.to_s, release_id: item.id.to_s)
      end
      expect(Job::Log.first.logs).to include(include("INFO -- : Completed Job"))
      expect(Job::Log.count).to eq 2

      releases = Cms::PageRelease.all.order_by(created: -1).entries
      releases.first.tap do |release|
        expect(release.state).to eq 'active'
        expect(release.action).to eq 'close'
        expect(release.es_state).to eq 'indexed'
      end
      expect(releases.size).to eq 2
    end
  end
end
