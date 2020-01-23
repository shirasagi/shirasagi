require 'spec_helper'

describe Cms::Elasticsearch::Indexer::PageReleaseJob, dbscope: :example, es: true do
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

  describe 'feed_all' do
    it do
      expect(page.status).to eq 'public'

      # index
      pages = Cms::Page.site(site).and_public
      pages.each do |page|
        job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
        job.perform_now(action: 'index', id: page.id.to_s)
      end
      expect(Job::Log.first.logs).to include(include("INFO -- : Completed Job"))
      expect(Job::Log.count).to eq 1
      expect(Cms::PageRelease.all.size).to eq 1
      expect(Cms::PageIndexQueue.all.size).to eq 1

      # remove queues
      Cms::PageIndexQueue.site(site).where(action: 'release').destroy_all
      expect(Cms::PageRelease.all.size).to eq 1
      expect(Cms::PageIndexQueue.all.size).to eq 0
    end
  end

  describe 'feed_releases' do
    it do
      # release

      expect(page.status).to eq 'public'

      releases = Cms::PageRelease.all.order_by(created: -1).entries
      releases.first.tap do |release|
        queue = Cms::PageIndexQueue.first
        expect(release.action).to eq 'release'
        expect(release.filename).to eq queue.filename
        expect(release.action).to eq queue.action
        expect(release.page_id).to eq queue.page_id
      end
      expect(releases.size).to eq 1
      expect(Cms::PageIndexQueue.all.size).to eq 1

      # index / release

      item = Cms::PageIndexQueue.site(site).order_by(created: -1).first
      expect(item.job_action).to eq 'index'

      job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
      job.perform_now(action: item.job_action, id: item.page_id.to_s, queue_id: item.id.to_s)
      expect(Job::Log.first.logs).to include(include("INFO -- : Completed Job"))
      expect(Job::Log.count).to eq 1
      expect(Cms::PageRelease.all.size).to eq 1
      expect(Cms::PageIndexQueue.all.size).to eq 0

      # close

      page.update(state: 'closed')

      releases = Cms::PageRelease.all.order_by(created: -1).entries
      releases.first.tap do |release|
        expect(release.action).to eq 'close'
      end
      expect(releases.size).to eq 2
      expect(Cms::PageIndexQueue.all.size).to eq 1

      # index / close

      item = Cms::PageIndexQueue.site(site).order_by(created: 1).first
      expect(item.job_action).to eq 'delete'

      job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
      job.perform_now(action: item.job_action, id: item.page_id.to_s, queue_id: item.id.to_s)
      expect(Job::Log.first.logs).to include(include("INFO -- : Completed Job"))
      expect(Job::Log.count).to eq 2
      expect(Cms::PageRelease.all.size).to eq 2
      expect(Cms::PageIndexQueue.all.size).to eq 0
    end
  end
end
