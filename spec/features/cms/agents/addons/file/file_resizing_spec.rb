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

  shared_examples "file resizing is" do
    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")

      within "#item-form #addon-cms-agents-addons-file" do
        wait_cbox_open do
          click_on button_label
        end
      end

      within "#ajax-box" do
        page.execute_script("SS_AjaxFile.firesEvents = true;")

        expect(page).to have_select('item[resizing]', selected: file_resizing_label)

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        # after save, confirm site-setting size is selected
        expect(page).to have_select('item[resizing]', selected: file_resizing_label)

        click_on I18n.t("ss.buttons.edit")
      end

      within "#ajax-box" do
        expect(page).to have_css(".ss-image-edit-canvas")
        within "#ajax-form" do
          click_on I18n.t("ss.buttons.cancel")
        end
      end

      within "#ajax-box" do
        # after edit-dialog is canceled, confirm site-setting size is selected
        expect(page).to have_select('item[resizing]', selected: file_resizing_label)

        wait_cbox_close do
          wait_event_to_fire "ss:ajaxFileSelected", "#addon-cms-agents-addons-file .ajax-box" do
            click_on 'keyvisual.jpg'
          end
        end
      end

      within "#item-form #addon-cms-agents-addons-file" do
        within '#selected-files' do
          expect(page).to have_css('.name', text: 'keyvisual.jpg')
        end
      end
    end
  end

  context "with cms/temp_file" do
    let(:button_label) { I18n.t("ss.buttons.upload") }

    before do
      expect(SS::File.all.count).to eq 0
    end

    it_behaves_like "file resizing is"

    after do
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

  context "with ss/user_file" do
    let(:button_label) { I18n.t("sns.user_file") }

    before do
      expect(SS::File.all.count).to eq 0
    end

    it_behaves_like "file resizing is"

    after do
      expect(SS::File.all.count).to eq 2
      expect(SS::File.all.where(model: "ss/user_file").count).to eq 1
      expect(SS::File.all.where(model: "ss/temp_file").count).to eq 1
      SS::File.all.where(model: "ss/user_file").first.tap do |file|
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

  context "with cms/file" do
    let(:button_label) { I18n.t("cms.file") }

    before do
      expect(SS::File.all.count).to eq 0
    end

    it_behaves_like "file resizing is"

    after do
      expect(SS::File.all.count).to eq 2
      expect(SS::File.all.where(model: "cms/file").count).to eq 1
      expect(SS::File.all.where(model: "ss/temp_file").count).to eq 1
      SS::File.all.where(model: "cms/file").first.tap do |file|
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
