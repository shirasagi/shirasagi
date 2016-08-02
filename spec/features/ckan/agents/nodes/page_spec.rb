require 'spec_helper'

describe Ckan::Agents::Nodes::PageController, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:status) { 200 }
  let(:body) { File.read "#{Rails.root}/spec/fixtures/ckan/package_search.json" }

  before { WebMock.reset! }
  after { WebMock.reset! }

  before do
    stub_request(:get, "#{node.ckan_url}/api/3/action/package_search?rows=10&sort=metadata_modified%20desc").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => status, :body => body, :headers => {})
  end

  context 'default loop html' do
    let(:node) { create :ckan_node_page, cur_site: site, layout_id: layout.id }

    it do
      visit node.full_url
      within 'article.item-test-dataset-1 header' do
        expect(page).to have_css('time', text: '2016年7月28日')
        expect(page).to have_css('h2 a', text: 'テストデータセット1')
        expect(page).to have_selector("h2 a[href='http://example.com/test-dataset-1']")
      end
    end
  end

  context 'loop html with all available variables' do
    let(:loop_html) do
      h = []
      h << '<article class="item-#{class} #{new}">'
      h << '  <p class="id">#{id}</p>'
      h << '  <p class="revision_id">#{revision_id}</p>'
      h << '  <p class="name">#{name}</p>'
      h << '  <p class="title">#{title}</p>'
      h << '  <p class="url">#{url}</p>'
      h << '  <p class="summary">#{summary}</p>'
      h << '  <p class="license_id">#{license_id}</p>'
      h << '  <p class="license_title">#{license_title}</p>'
      h << '  <p class="license_url">#{license_url}</p>'
      h << '  <p class="author">#{author}</p>'
      h << '  <p class="author_email">#{author_email}</p>'
      h << '  <p class="maintainer">#{maintainer}</p>'
      h << '  <p class="maintainer_email">#{maintainer_email}</p>'
      h << '  <p class="num_tags">#{num_tags}</p>'
      h << '  <p class="num_resources">#{num_resources}</p>'
      h << '  <p class="private">#{private}</p>'
      h << '  <p class="state">#{state}</p>'
      h << '  <p class="version">#{version}</p>'
      h << '  <p class="type">#{type}</p>'
      h << '  <p class="new">#{new}</p>'
      h << '  <p class="created_date">#{created_date}</p>'
      h << '  <p class="created_date_iso">#{created_date.iso}</p>'
      h << '  <p class="created_date_long">#{created_date.long}</p>'
      h << '  <p class="updated_date">#{updated_date}</p>'
      h << '  <p class="updated_date_iso">#{updated_date.iso}</p>'
      h << '  <p class="updated_date_long">#{updated_date.long}</p>'
      h << '  <p class="created_time">#{created_time}</p>'
      h << '  <p class="created_time_iso">#{created_time.iso}</p>'
      h << '  <p class="created_time_long">#{created_time.long}</p>'
      h << '  <p class="updated_time">#{updated_time}</p>'
      h << '  <p class="updated_time_iso">#{updated_time.iso}</p>'
      h << '  <p class="updated_time_long">#{updated_time.long}</p>'
      h << '  <p class="group">#{group}</p>'
      h << '  <p class="groups">#{groups}</p>'
      h << '  <p class="organization">#{organization}</p>'
      h << '  <p class="add_or_update">#{add_or_update}</p>'
      h << '  <p class="add_or_update_text">#{add_or_update_text}</p>'
      h << '</article>'
      h.join("\n")
    end

    let(:node) { create :ckan_node_page, cur_site: site, layout_id: layout.id, loop_html: loop_html }

    it do
      visit node.full_url
      within 'article.item-test-dataset-1' do
        expect(page).to have_css('.id', text: '58a796a2-b085-43f4-9c05-b2b97395a871')
        expect(page).to have_css('.revision_id', text: '3d0665cf-1a68-4319-8b27-6fba35389055')
        expect(page).to have_css('.name', text: 'test-dataset-1')
        expect(page).to have_css('.title', text: 'テストデータセット1')
        expect(page).to have_css('.url', text: 'http://example.com/test-dataset-1')
        expect(page).to have_css('.summary', text: 'これはテストデータセット1です。')
        expect(page).to have_css('.license_id', text: 'cc-by')
        expect(page).to have_css('.license_title', text: 'Creative Commons Attribution')
        expect(page).to have_css('.license_url', text: 'http://www.opendefinition.org/licenses/cc-by')
        expect(page).to have_css('.author', text: 'author')
        expect(page).to have_css('.author_email', text: 'author@example.jp')
        expect(page).to have_css('.maintainer', text: 'maintainer')
        expect(page).to have_css('.maintainer_email', text: 'maintainer@example.jp')
        expect(page).to have_css('.num_tags', text: '1')
        expect(page).to have_css('.num_resources', text: '12')
        expect(page).to have_css('.private', text: 'false')
        expect(page).to have_css('.state', text: 'active')
        expect(page).to have_css('.version', text: '1.5')
        expect(page).to have_css('.type', text: 'dataset')
        expect(page).to have_css('.new', text: '')
        expect(page).to have_css('.created_date', text: '2016/7/23')
        expect(page).to have_css('.created_date_iso', text: '2016-07-23')
        expect(page).to have_css('.created_date_long', text: '2016年7月23日')
        expect(page).to have_css('.updated_date', text: '2016/7/28')
        expect(page).to have_css('.updated_date_iso', text: '2016-07-28')
        expect(page).to have_css('.updated_date_long', text: '2016年7月28日')
        expect(page).to have_css('.created_time', text: '2016/7/23 08:31')
        expect(page).to have_css('.created_time_iso', text: '2016-07-23 08:31')
        expect(page).to have_css('.created_time_long', text: '2016年7月23日 08時31分')
        expect(page).to have_css('.updated_time', text: '2016/7/28 06:58')
        expect(page).to have_css('.updated_time_iso', text: '2016-07-28 06:58')
        expect(page).to have_css('.updated_time_long', text: '2016年7月28日 06時58分')
        expect(page).to have_css('.group', text: 'グループ1')
        expect(page).to have_css('.groups', text: 'グループ1, グループ2')
        expect(page).to have_css('.organization', text: '組織1')
        expect(page).to have_css('.add_or_update', text: '')
        expect(page).to have_css('.add_or_update_text', text: '')
      end
    end
  end
end
