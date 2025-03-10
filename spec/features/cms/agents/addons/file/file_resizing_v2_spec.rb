require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:item) { create(:article_page, cur_site: site, cur_node: node) }
  let(:file_resizing) { [ rand(50..99), rand(50..99) ] }
  let(:file_resizing_label) { site.t(:file_resizing_label, size: file_resizing.join("x")) }

  before do
    site.set(file_resizing: file_resizing)

    login_cms_user
  end

  context "with cms/temp_file(ss/temp_file)" do
    let(:button_label) { I18n.t("ss.buttons.upload") }

    before do
      expect(SS::File.all.count).to eq 0
    end

    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "#item-form #addon-cms-agents-addons-file" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.buttons.upload")
        end
      end

      within_dialog do
        attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      end

      within_dialog do
        within ".index" do
          within first("tbody tr") do
            expect(page).to have_select("item[files][][resizing]", selected: file_resizing_label)
          end
        end
      end

      wait_for_cbox_closed do
        within_dialog do
          within "form" do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end

      within "#item-form #addon-cms-agents-addons-file" do
        within '#selected-files' do
          expect(page).to have_css('.name', text: 'keyvisual.jpg')
        end
      end

      expect(SS::File.all.count).to eq 1
      expect(SS::File.all.where(model: "ss/temp_file").count).to eq 1
      SS::File.all.where(model: "ss/temp_file").first.tap do |file|
        dimension = file.image_dimension
        expect(dimension).to be_present
        expect(dimension[0]).to be <= file_resizing[0]
        expect(dimension[1]).to be <= file_resizing[1]

        thumb = file.thumb
        thumb_dimension = thumb.image_dimension
        expect(thumb_dimension).to be_present
        expect(thumb_dimension[0]).to be <= dimension[0]
        expect(thumb_dimension[1]).to be <= dimension[1]
      end
    end
  end
end
