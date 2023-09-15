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
end
