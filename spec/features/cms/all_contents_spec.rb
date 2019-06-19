require 'spec_helper'

describe "cms_all_contents", dbscope: :example, type: :feature do
  subject(:site) { cms_site }

  before { login_cms_user }

  describe "download_all" do
    let(:layout) { create(:cms_layout, cur_site: site) }
    let(:cate) { create(:category_node_node, cur_site: site) }
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
      visit cms_all_contents_path(site: site)
      click_on I18n.t("ss.buttons.download")

      expect(page.response_headers["Transfer-Encoding"]).to eq "chunked"
      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv = csv.encode("UTF-8", "SJIS")
      csv = ::CSV.parse(csv)

      expect(csv.length).to eq 4
      expect(csv[0]).to eq Cms::AllContent.header
    end
  end

  describe "import" do
    context "upload csv file" do
      it do
        visit cms_all_contents_path(site: site)
        click_on I18n.t("cms.all_content.import_tab")

        expectation = expect do
          within "form" do
            attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/all_contents_1.csv"
            click_on I18n.t("ss.import")
          end
        end
        expectation.to have_enqueued_job(Cms::AllContentsImportJob)
        expect(page).to have_css("#notice", text: I18n.t('ss.notice.started_import'))
      end
    end

    context "upload invalid csv file (png file)" do
      it do
        visit cms_all_contents_path(site: site)
        click_on I18n.t("cms.all_content.import_tab")

        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_on I18n.t("ss.import")
        end

        expect(page).to have_css("#errorExplanation", text: I18n.t("errors.messages.invalid_csv"))
      end
    end

    context "upload malformed csv file" do
      it do
        visit cms_all_contents_path(site: site)
        click_on I18n.t("cms.all_content.import_tab")

        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/facility/facility.csv"
          click_on I18n.t("ss.import")
        end

        expect(page).to have_css("#errorExplanation", text: I18n.t("errors.messages.malformed_csv"))
      end
    end
  end
end
