require 'spec_helper'

describe Gws::Bookmark, type: :model, dbscope: :example do
  let(:site) { gws_site }

  describe ".bookmark_model_options_all" do
    context "with all menus available" do
      let(:private_types) { 1 }
      let(:public_types) { Gws::Bookmark::BOOKMARK_MODEL_ALL_TYPES.count - private_types }

      it do
        public_options, private_options = Gws::Bookmark.bookmark_model_options_all(site)
        expect(public_options).to have(public_types).items
        expect(private_options).to have(private_types).items
        expect(private_options).to include([ I18n.t("modules.gws/elasticsearch"), "elasticsearch" ])
      end
    end

    context "with all menus available" do
      let(:disabled_menu) { (Gws::Bookmark::BOOKMARK_MODEL_TYPES - %w(elasticsearch)).sample }
      let(:private_types) { 2 }
      let(:public_types) { Gws::Bookmark::BOOKMARK_MODEL_ALL_TYPES.count - private_types }

      before do
        site.update("menu_#{disabled_menu}_state" => "hide")
      end

      it do
        public_options, private_options = Gws::Bookmark.bookmark_model_options_all(site)
        expect(public_options).to have(public_types).items
        expect(private_options).to have(private_types).items
        expect(private_options).to include([ I18n.t("modules.gws/#{disabled_menu}"), disabled_menu ])
      end
    end
  end
end
