require 'spec_helper'

describe 'cms_agents_nodes_site_search', type: :feature, dbscope: :example, js: true, es: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout }
  let!(:node) { create :cms_node, layout_id: layout.id, filename: "node" }
  let!(:site_search_node) { create :cms_node_site_search, cur_site: site, cur_node: node }

  let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:cate1) { create :category_node_page }
  let!(:cate2) { create :category_node_page }
  let!(:file1) { create :ss_file, site_id: site.id, user_id: user.id }
  let!(:file2) { create :ss_file, site_id: site.id, user_id: user.id }

  let!(:item1) { create :cms_page, cur_node: node, layout: layout, name: 'name1' }
  let!(:item2) do
    create :article_page, cur_node: node, layout: layout, name: 'name2',
      file_ids: [file1.id], category_ids: [cate1.id], group_ids: [group1.id],
      html: '<img src="' + file1.url + '" alt="alt" title="title">'
  end

  let!(:form) do
    create :cms_form, cur_site: site, state: 'public', sub_type: 'static',
      html: 'bbb{{ values["image"] }}bbb'
  end
  let!(:column) do
    create :cms_column_file_upload, cur_site: site, cur_form: form, file_type: 'image',
      name: 'image'
  end
  let!(:item3) do
    create :article_page, cur_node: node, layout: layout, form: form, name: 'name3',
      file_ids: [file2.id], category_ids: [cate2.id], group_ids: [group2.id],
      column_values: [
        column.value_type.new(column: column, file_id: file2.id, image_html_type: 'image')
      ]
  end

  before do
    ::Cms::Elasticsearch.init_ingest(site: site)
    ::Cms::Elasticsearch.drop_index(site: site) rescue nil
    ::Cms::Elasticsearch.create_index(site: site)

    Cms::PageIndexQueue.site(site).each do |item|
      job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site.id)
      ss_perform_now(job, action: item.job_action, id: item.page_id.to_s, queue_id: item.id.to_s)
    end
  end

  context 'image' do
    it do
      visit site_search_node.url

      within '.search-form' do
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages .item:nth-child(2)' do
        expect(page).to have_css('.title')
        expect(page).to have_css('.summary .image')
        expect(page).to have_css('.summary .text')
        expect(page).to have_css('.meta .url')
        expect(page).to have_css('.meta .date')
        expect(page).to have_css('.meta .category-list')
      end
      within '.pages .item:nth-child(3)' do
        expect(page).to have_css('.title')
        expect(page).to have_css('.summary .image')
        expect(page).to have_css('.summary .text')
        expect(page).to have_css('.meta .url')
        expect(page).to have_css('.meta .date')
        expect(page).to have_css('.meta .category-list')
      end

      ## category
      within '.search-form' do
        fill_in 's[category_name]', with: "#{cate1.name} etc"
        fill_in 's[group_name]', with: ''
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages' do
        expect(page.all('.item').count).to eq 1
      end

      ## group
      within '.search-form' do
        fill_in 's[category_name]', with: ''
        fill_in 's[group_name]', with: "#{group1.name.split('/').last} etc"
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages' do
        expect(page.all('.item').count).to eq 1
      end
    end
  end

  context 'og:image' do
    before do
      server = Capybara.current_session.server
      site.opengraph_type = 'article'
      site.opengraph_defaul_image_url = "http://#{server.host}:#{server.port}/assets/img/logo.png"
      site.save
    end

    it do
      visit site_search_node.url

      within '.search-form' do
        click_button I18n.t('ss.buttons.search')
      end

      within '.pages article:nth-child(1)' do
        expect(page).to have_selector("img[alt='og:image']")
      end
    end
  end
end
