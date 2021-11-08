require 'spec_helper'

describe "cms_folder_sizes", type: :feature, dbscope: :example do
  subject(:site) { cms_site }

  before do
    @save_config = SS.config.cms.cms_sitemap
    SS.config.replace_value_at(:cms, 'cms_sitemap', "disable" => false)
    Cms::Role.permission :use_cms_sitemap
    cms_role.add_to_set(permissions: %w(use_cms_sitemap))
    login_cms_user
  end

  after do
    SS.config.replace_value_at(:cms, 'cms_sitemap', @save_config)
  end

  describe "index" do
    let(:user) { cms_user }

    it "visible portals" do
      visit cms_search_contents_sitemap_path(site: site, user: user)
      expect(page).to have_content(user.name)
    end

    it "secured portals" do
      role = user.cms_roles[0]
      role.update(permissions: %w(use_cms_sitemap))
      role.update(permissions: nil)
      visit cms_search_contents_sitemap_path(site: site, user: user)
      expect(page).to have_title("403")
    end

  end

  describe "download_all" do
    let(:layout) { create(:cms_layout, cur_site: site) }
    let(:cate) { create(:category_node_node, cur_site: site) }
    let(:index_path) { cms_search_contents_sitemap_path(site: site) }
    let(:download_all_path) { cms_folder_csv_download_path(site: site, format: :csv) }
    let!(:node) do
      create(:article_node_page, cur_site: site, layout_id: layout.id, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end
    let!(:item) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, category_ids: [ cate.id ],
        group_ids: [ cms_group.id ]
      )
    end

    it do
      visit index_path
      click_on I18n.t("cms.links.download")
      expect(current_path).to eq download_all_path
      expect(page.response_headers["Transfer-Encoding"]).to eq "chunked"
      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv = csv.encode("UTF-8", "SJIS")
      csv = ::CSV.parse(csv)

      expect(csv.length).to eq 3
      expect(csv[0]).to eq Cms::FolderSize.header
    end
  end
end
