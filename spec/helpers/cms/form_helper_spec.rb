require 'spec_helper'

describe Cms::FormHelper, type: :helper, dbscope: :example do
  describe "#ancestral_forms" do
    let!(:user) { cms_user }
    let!(:site0) { cms_site }
    let!(:site1) { create :cms_site_unique }
    let!(:site0_form) { create :cms_form, cur_site: site0, state: "public" }
    let!(:site1_form) { create :cms_form, cur_site: site1, state: "public" }

    before do
      user.add_to_set(group_ids: site1.id)
    end

    context "without node" do
      before do
        @cur_site = site0
        @cur_user = user
        @cur_path = "/index.html"
      end

      it do
        forms = helper.ancestral_forms
        expect(forms.count).to eq 1
        expect(forms.pluck(:name)).to include(site0_form.name)
      end
    end

    context "with article/node" do
      let!(:node) { create :article_node_page, cur_site: site0, st_form_ids: [ site0_form.id, site1_form ] }

      before do
        @cur_site = site0
        @cur_node = node
        @cur_user = user
        @cur_path = "/#{node.filename}/page1.html"
      end

      it do
        forms = helper.ancestral_forms
        expect(forms.count).to eq 1
        expect(forms.pluck(:name)).to include(site0_form.name)
      end
    end
  end

  describe "#ancestral_loop_settings" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }
    let!(:shirasagi_setting) { create(:cms_loop_setting, site: site, html_format: "shirasagi", state: "public") }
    let!(:liquid_setting) { create(:cms_loop_setting, site: site, html_format: "liquid", state: "public") }
    let!(:closed_setting) { create(:cms_loop_setting, site: site, html_format: "shirasagi", state: "closed") }

    before do
      @cur_site = site
      @cur_user = user
    end

    it "returns only public shirasagi format loop settings" do
      settings = helper.ancestral_loop_settings
      expect(settings.count).to eq 1
      expect(settings.first[0]).to eq shirasagi_setting.name
      expect(settings.first[1]).to eq shirasagi_setting.id
    end

    it "does not include liquid format settings" do
      settings = helper.ancestral_loop_settings
      liquid_names = settings.map { |name, _id| name }
      expect(liquid_names).not_to include(liquid_setting.name)
    end

    it "does not include closed settings" do
      settings = helper.ancestral_loop_settings
      closed_names = settings.map { |name, _id| name }
      expect(closed_names).not_to include(closed_setting.name)
    end
  end

  describe "#ancestral_custom_html_settings" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }
    let!(:shirasagi_setting) { create(:cms_loop_setting, site: site, html_format: "shirasagi", state: "public") }
    let!(:liquid_setting) { create(:cms_loop_setting, site: site, html_format: "liquid", state: "public") }
    let!(:closed_setting) { create(:cms_loop_setting, site: site, html_format: "liquid", state: "closed") }

    before do
      @cur_site = site
      @cur_user = user
    end

    it "returns only public liquid format loop settings" do
      settings = helper.ancestral_custom_html_settings
      expect(settings.count).to eq 1
      expect(settings.first[0]).to eq liquid_setting.name
      expect(settings.first[1]).to eq liquid_setting.id
    end

    it "does not include shirasagi format settings" do
      settings = helper.ancestral_custom_html_settings
      shirasagi_names = settings.map { |name, _id| name }
      expect(shirasagi_names).not_to include(shirasagi_setting.name)
    end

    it "does not include closed settings" do
      settings = helper.ancestral_custom_html_settings
      closed_names = settings.map { |name, _id| name }
      expect(closed_names).not_to include(closed_setting.name)
    end
  end
end
