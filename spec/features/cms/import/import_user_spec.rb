require 'spec_helper'

describe "cms_import", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let(:file) { "#{Rails.root}/spec/fixtures/cms/import/site.zip" }
  let(:name) { File.basename(file, ".*") }
  let(:now) { Time.zone.now.beginning_of_minute }

  let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
  let!(:group3) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }

  let!(:cms_role_ids) { cms_user.cms_role_ids }
  let!(:user1) { create :cms_user, name: unique_id, group_ids: [group1.id], cms_role_ids: cms_role_ids }
  let!(:user2) { create :cms_user, name: unique_id, group_ids: [group2.id, group3.id], cms_role_ids: cms_role_ids }
  let(:index_path) { cms_import_path site }

  shared_examples "import by user" do
    before { login_user(user) }

    it "#import" do
      expect(Cms::Node.site(site).count).to eq 0
      expect(Cms::Page.site(site).count).to eq 0

      visit index_path

      within "form#task-form" do
        attach_file "item[in_file]", file
        fill_in 'item[import_date]', with: I18n.l(now, format: :long)
        click_button I18n.t('ss.buttons.import')
      end
      wait_for_notice I18n.t('ss.notice.started_import')

      root_node = Cms::Node.site(site).find_by(filename: "site")
      expect(root_node.user_id).to eq user.id
      expect(root_node.group_ids).to match_array user.group_ids

      perform_enqueued_jobs

      expect(Cms::Node.site(site).count).to eq 4
      expect(Cms::Page.site(site).count).to eq 2
      Cms::Node.site(site).each do |item|
        expect(item.user_id).to eq user.id
        expect(item.group_ids).to match_array user.group_ids
      end
      Cms::Page.site(site).each do |item|
        expect(item.user_id).to eq user.id
        expect(item.group_ids).to match_array user.group_ids
      end
    end
  end

  context "with user1" do
    let(:user) { user1 }
    it_behaves_like "import by user"
  end

  context "with user2" do
    let(:user) { user2 }
    it_behaves_like "import by user"
  end
end
