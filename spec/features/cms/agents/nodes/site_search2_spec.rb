require 'spec_helper'

describe 'cms_agents_nodes_site_search', type: :feature, dbscope: :example, js: true, es: true do
  let!(:site) { cms_site }
  let!(:site2) { create :cms_site_subdir, parent_id: site.id }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout }
  let!(:node) { create :article_node_page, layout_id: layout.id, filename: "node" }
  let!(:site_search_node) { create :cms_node_site_search, cur_site: site, cur_node: node }

  let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:cate1) { create :category_node_page }
  let!(:cate2) { create :category_node_page }
  let!(:file1) { create :ss_file, site_id: site.id, user_id: user.id }
  let!(:file2) { create :ss_file, site_id: site.id, user_id: user.id }

  let!(:item1) { create :cms_page, cur_node: node, layout: layout, name: 'page1' }
  let!(:item2) do
    create :article_page, cur_node: node, layout: layout, name: 'page2',
      file_ids: [file1.id], category_ids: [cate1.id], group_ids: [group1.id],
      html: '<img src="' + file1.url + '" alt="alt" title="title">'
  end

  let!(:form) do
    create :cms_form, cur_site: site, state: 'public', sub_type: 'static',
      html: '{{ values["image"] }}'
  end
  let!(:column) do
    create :cms_column_file_upload, cur_site: site, cur_form: form, file_type: 'image',
      name: 'image'
  end
  let!(:item3) do
    create :article_page, cur_node: node, layout: layout, form: form, name: 'page3',
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
    ::Cms::Elasticsearch.refresh_index(site: site)
    expect(Cms::PageRelease.all.size).to eq 3
    expect(Cms::PageIndexQueue.all.size).to eq 0
  end

  context 'one site with settings' do
    before do
      site_search_node.update st_article_node_ids: [node.id], st_category_ids: [cate1.id]
    end

    it do
      visit site_search_node.url

      within '.search-form' do
        expect(page.all("select[name='s[article_node_ids][]'] option").count).to eq 2
        expect(page.all("select[name='s[category_names][]'] option").count).to eq 2
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages .item:nth-child(1)' do
        expect(page).not_to have_selector('img')
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

      ## article_node
      within '.search-form' do
        find("select[name='s[article_node_ids][]'] option[value='#{node.id}']").select_option
        find("select[name='s[category_names][]'] option[value='']").select_option
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages' do
        expect(page.all('.item').count).to eq 3
      end

      ## category
      within '.search-form' do
        find("select[name='s[article_node_ids][]'] option[value='']").select_option
        find("select[name='s[category_names][]'] option[value='#{cate1.name}']").select_option
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages' do
        expect(page.all('.item').count).to eq 1
      end
    end
  end

  context 'one site without settings' do
    it do
      visit site_search_node.url

      within '.search-form' do
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages .item:nth-child(1)' do
        expect(page).not_to have_selector('img')
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
        find("select[name='s[category_names][]'] option[value='#{cate1.name}']").select_option
        find("select[name='s[group_ids][]'] option[value='']").select_option
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages' do
        expect(page.all('.item').count).to eq 1
      end

      ## group
      within '.search-form' do
        find("select[name='s[category_names][]'] option[value='']").select_option
        find("select[name='s[group_ids][]'] option[value='#{group1.id}']").select_option
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
      within '.pages .item:nth-child(1)' do
        expect(page).to have_selector("img[alt='og:image']")
      end
    end
  end

  context 'search for attachment' do
    it do
      visit site_search_node.url

      within '.search-form' do
        find("select[name='s[type]'] option[value='file']").select_option
        click_button I18n.t('ss.buttons.search')
      end
      within '.pages .item:nth-child(1)' do
        expect(page).to have_css('.title')
        expect(page).to have_css('.summary .image')
        expect(page).to have_css('.meta .page-name')
        expect(page).to have_css('.meta .url')
        expect(page).to have_css('.meta .date')
        expect(page).to have_css('.meta .category-list')
      end
    end
  end

  context 'multiple sites' do
    before do
      site.update elasticsearch_site_ids: [site.id, site2.id], elasticsearch_outside: 'enabled'
      site2.update elasticsearch_hosts: es_url

      ::Cms::Elasticsearch.init_ingest(site: site2)
      ::Cms::Elasticsearch.drop_index(site: site2) rescue nil
      ::Cms::Elasticsearch.create_index(site: site2)

      Cms::PageIndexQueue.site(site2).each do |item|
        job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site2.id)
        ss_perform_now(job, action: item.job_action, id: item.page_id.to_s, queue_id: item.id.to_s)
      end
      ::Cms::Elasticsearch.refresh_index(site: site2)
    end

    context 'search for target' do
      it do
        visit site_search_node.url

        within '.search-form' do
          find("select[name='target'] option[value='outside']").select_option
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
      end
    end

    context 'text field is placed' do
      it do
        visit site_search_node.url

        within '.search-form' do
          click_button I18n.t('ss.buttons.search')
        end
        within '.pages .item:nth-child(1)' do
          expect(page).not_to have_selector('img')
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
  end
end
