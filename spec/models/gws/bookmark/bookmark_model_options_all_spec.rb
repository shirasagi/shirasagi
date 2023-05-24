require 'spec_helper'

describe Gws::Bookmark, type: :model, dbscope: :example do
  let(:site) { gws_site }

  describe ".bookmark_model_options_all" do
    context "with all menus available" do
      it do
        public_options, private_options = Gws::Bookmark.bookmark_model_options_all(site)
        expect(public_options).to have(26).items
        expect(private_options).to have(1).items
        expect(private_options).to include([ I18n.t("modules.gws/elasticsearch"), "elasticsearch" ])
      end
    end

    context "with all menus available" do
      let(:disabled_menu) { (Gws::Bookmark::BOOKMARK_MODEL_TYPES - %w(elasticsearch)).sample }

      before do
        site.update("menu_#{disabled_menu}_state" => "hide")
      end

      it do
        public_options, private_options = Gws::Bookmark.bookmark_model_options_all(site)
        expect(public_options).to have(25).items
        expect(private_options).to have(2).items
        expect(private_options).to include([ I18n.t("modules.gws/#{disabled_menu}"), disabled_menu ])
      end
    end
  end
end
