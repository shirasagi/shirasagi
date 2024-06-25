require 'spec_helper'

describe "cms_apis_pages", type: :feature, dbscope: :example do
  let(:partner_site) { cms_site }
  let(:master_site) { create(:cms_site, host: unique_id, domains: [unique_id]) }
  let(:node) { create(:article_node_page) }
  let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
  let(:page_s1) { create(:cms_page, cur_site: partner_site, html: html) }
  let(:page_s2) { create(:cms_page, cur_site: master_site, html: html) }
  let(:index_path) {cms_apis_pages_path(site: partner_site, s: {partner_site: nil}) }
  let(:index_path_for_partner_path) {cms_apis_pages_path(site: partner_site, s: {partner_site: master_site.id})}

  context "admin user checking page tabs" do 
    before do 
      login_cms_user
      master_site.update(partner_site_ids: [partner_site.id])
      page_s1.save!
      page_s2.save!
    end

    describe "Check the correct articles for current site e.g (master_site)" do 
      it do 
        visit index_path
        within("a.current") do
          expect(page).to have_css("span", text: partner_site.name)
        end
        expect(page).to have_css("tr[data-id='#{page_s1.id}']")
        expect(page).to have_css("tr.list-item", count: 1)
      end
    end

    describe "Check the correct articles for partner_site site e.g (partner_site)" do 
      it do 
        visit index_path_for_partner_path
        within("a.current") do
          expect(page).to have_css("span", text: master_site.name)
        end
        expect(page).to have_css("tr[data-id='#{page_s2.id}']")
        expect(page).to have_css("tr.list-item", count: 1)
      end
    end

  end
end