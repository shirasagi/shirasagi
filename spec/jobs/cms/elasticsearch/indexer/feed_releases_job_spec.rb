require 'spec_helper'

describe Cms::Elasticsearch::Indexer::FeedReleasesJob, dbscope: :example, es: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:file) { tmp_ss_file(user: user, contents: file_path, binary: true, content_type: 'image/png') }
  let!(:node) { create(:article_node_page, cur_site: site) }
  let!(:page) { create(:article_page, cur_site: site, cur_node: node, file_ids: [file.id], state: "closed") }

  it do
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
    expect(es_requests.length).to eq 0

    # cms:es:fee_releases タスクに相当するジョブ（毎時実行する処理）を実行
    described_class.bind(site_id: site).perform_now

    expect(Job::Log.all.count).to eq 2
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
    expect(Cms::PageRelease.all.count).to eq 1
    expect(Cms::PageIndexQueue.all.count).to eq 0
    expect(es_requests.length).to eq 1
    es_requests[0].tap do |request|
      expect(request['method']).to eq 'delete'
      expect(request['uri']['path']).to end_with("/#{CGI.escape(page.filename)}")
      expect(request['body']).to be_blank
    end
    # TODO: 添付ファイルを削除するリクエストが発行されていないがいいのだろうか？
    es_requests.clear

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
    expect(es_requests.length).to eq 0

    # cms:es:fee_releases タスクに相当するジョブ（毎時実行する処理）を実行
    described_class.bind(site_id: site).perform_now

    expect(Job::Log.all.count).to eq 4
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
    expect(Cms::PageRelease.all.count).to eq 2
    expect(Cms::PageIndexQueue.all.count).to eq 0
    expect(es_requests.length).to eq 2
    es_requests[0].tap do |request|
      expect(request['method']).to eq 'put'
      expect(request['uri']['path']).to end_with("/#{CGI.escape(page.filename)}")
      body = JSON.parse(request['body'])
      expect(body['url']).to eq page.url
    end
    es_requests[1].tap do |request|
      expect(request['method']).to eq 'put'
      expect(request['uri']['path']).to end_with("/file-#{file.id}")
      body = JSON.parse(request['body'])
      # TODO: 添付ファイルの URL が、ページの URL と同じでいいの？
      expect(body['url']).to eq page.url
    end
    es_requests.clear

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
    expect(es_requests.length).to eq 0

    # cms:es:fee_releases タスクに相当するジョブ（毎時実行する処理）を実行
    described_class.bind(site_id: site).perform_now

    expect(Job::Log.all.count).to eq 6
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
    expect(Cms::PageRelease.all.count).to eq 3
    expect(Cms::PageIndexQueue.all.count).to eq 0
    expect(es_requests.length).to eq 1
    es_requests[0].tap do |request|
      expect(request['method']).to eq 'delete'
      expect(request['uri']['path']).to end_with("/#{CGI.escape(page.filename)}")
      expect(request['body']).to be_blank
    end
    # TODO: 添付ファイルを削除するリクエストが発行されていないが、これは間違いなくバグだ。添付ファイルが ES 上に残ってしまう。
    # es_requests[1].tap do |request|
    #   expect(request['method']).to eq 'delete'
    #   expect(request['uri']['path']).to end_with("/file-#{file.id}")
    #   expect(request['body']).to be_blank
    # end
    es_requests.clear
  end
end
