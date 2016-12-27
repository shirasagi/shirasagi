require 'spec_helper'

describe "jmaxml/action/publish_pages", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :rss_node_weather_xml, cur_site: site }
  let(:index_path) { jmaxml_action_bases_path(site, node) }

  context "basic crud" do
    let!(:article_node) { create(:article_node_page) }
    let!(:category_node) { create(:category_node_page) }
    let(:model) { Jmaxml::Action::PublishPage }
    let(:name1) { unique_id }
    let(:name2) { unique_id }

    before { login_cms_user }

    it do
      #
      # create
      #
      visit index_path
      click_on I18n.t('views.links.new')

      within 'form' do
        select model.model_name.human, from: 'item[in_type]'
        click_on I18n.t('views.button.new')
      end

      within 'form' do
        fill_in 'item[name]', with: name1
        click_on I18n.t('cms.apis.nodes.index')
      end
      within '.items' do
        click_on article_node.name
      end
      within 'form' do
        click_on I18n.t('cms.apis.categories.index')
      end
      within '.items' do
        click_on category_node.name
      end
      within 'form' do
        click_on I18n.t('views.button.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |action|
        expect(action.name).to eq name1
        expect(action.publish_to_id).to eq article_node.id
        expect(action.publish_state).to eq 'draft'
        expect(action.category_ids).to eq [ category_node.id ]
        expect(action.publishing_office_state).to eq 'hide'
      end

      #
      # update
      #
      visit index_path
      click_on name1
      click_on I18n.t('views.links.edit')

      within 'form' do
        fill_in 'item[name]', with: name2
        click_on I18n.t('views.button.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |action|
        expect(action.name).to eq name2
        expect(action.publish_to_id).to eq article_node.id
        expect(action.publish_state).to eq 'draft'
        expect(action.category_ids).to eq [ category_node.id ]
        expect(action.publishing_office_state).to eq 'hide'
      end

      #
      # delete
      #
      visit index_path
      click_on name2
      click_on I18n.t('views.links.delete')

      within 'form' do
        click_on I18n.t('views.button.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      expect(model.count).to eq 0
    end
  end
end
