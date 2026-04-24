require 'spec_helper'

describe "category_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:item) { create :category_node_node, filename: "#{node.filename}/name" }
  let(:backup_item) { item.backups.first }
  let(:index_path)  { category_nodes_path site.id, node }
  let(:edit_path)   { "#{index_path}/#{item.id}/edit" }
  let(:thumb_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s }
  let!(:file) { tmp_ss_file(Cms::TempFile, cur_user: cms_user, site: site, node: node, contents: thumb_path) }

  context "with auth" do
    before { login_cms_user }

    it do
      visit edit_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        attach_to_ss_file_field "item[thumb_id]", file
        click_button I18n.t('ss.buttons.save')
      end

      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      expect(SS::File.all.count).to eq 1
      SS::File.all.first.tap do |file|
        expect(file.site_id).to eq site.id
        expect(file.user_id).to eq cms_user.id
        expect(file.model).to eq "category/node/node"
        expect(file.name).to eq "logo.png"
        expect(file.filename).to eq "logo.png"
        expect(file.content_type).to eq "image/png"
        expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
      end

      visit edit_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      click_on I18n.t('ss.links.change')
      within 'article.mod-category' do
        click_on I18n.t('cms.nodes.category/page')
      end

      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        click_button I18n.t('ss.buttons.save')
      end

      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      expect(SS::File.all.count).to eq 1
      SS::File.all.first.tap do |file|
        expect(file.site_id).to eq site.id
        expect(file.user_id).to eq cms_user.id
        expect(file.model).to eq "category/node/page"
        expect(file.name).to eq "logo.png"
        expect(file.filename).to eq "logo.png"
        expect(file.content_type).to eq "image/png"
        expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
      end

      within "[data-id='#{backup_item.id}']" do
        click_link I18n.t('history.compare_backup_to_previsous')
      end

      expect(page).to have_css(".history-backup")
    end
  end
end
