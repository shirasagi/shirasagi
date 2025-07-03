require 'spec_helper'

describe Gws::Tabular::View::DefaultView, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) do
    create(:gws_tabular_form, cur_site: site, cur_space: space, state: 'closed', revision: 1, workflow_state: 'disabled')
  end

  describe "#to_key" do
    it do
      view = Gws::Tabular::View::DefaultView.new(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      expect(view.to_key).to eq [ "-" ]
    end
  end

  describe "#to_param" do
    it do
      view = Gws::Tabular::View::DefaultView.new(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      expect(view.to_param).to eq "-"
    end
  end

  context "url_helpers" do
    it do
      view = Gws::Tabular::View::DefaultView.new(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      path = Rails.application.routes.url_helpers.gws_tabular_files_path(site: site, space: space, form: form, view: view)
      expect(path).to eq "/.g#{site.id}/tabular/#{space.id}/#{form.id}/-/files"
    end
  end
end
