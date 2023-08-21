require 'spec_helper'

describe "inquiry_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'enabled',
      notice_state: 'enabled',
      notice_content: 'include_answers',
      notice_email: 'notice@example.jp',
      from_name: 'admin',
      from_email: 'admin@example.jp',
      reply_state: 'enabled')
  end
  let(:conf_path) { node_conf_path(site, node) }

  context "email column exists" do
    before do
      node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site})
      node.reload

      login_cms_user
    end

    it do
      visit conf_path
      within "#addon-inquiry-agents-addons-reply" do
        expect(page).to have_no_css(".email-column-not-exists")
      end
    end
  end

  context "email column not exists" do
    before do
      node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
      node.reload

      login_cms_user
    end

    it do
      visit conf_path
      within "#addon-inquiry-agents-addons-reply" do
        expect(page).to have_css(".email-column-not-exists")
      end
    end
  end
end
