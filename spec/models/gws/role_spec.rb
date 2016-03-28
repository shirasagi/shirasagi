require 'spec_helper'

describe Gws::Role, type: :model, dbscope: :example do
  let(:model) { Gws::Role }

  describe "find" do
    it { expect(model.new.permission_level_options).to eq [%w(1 1), %w(2 2), %w(3 3)] }
    it { expect(model.mod_name(:gws)).to eq I18n.t("modules.gws") }
    it { expect(model.search(keyword: "unknown_name").first).to eq nil}
  end

  describe "attributes" do
    it { expect(model.new.permission_level_options).to eq [%w(1 1), %w(2 2), %w(3 3)] }
    it { expect(model.mod_name(:gws)).to eq I18n.t("modules.gws") }
  end

  describe "validation" do
    it { expect(model.new.save).to eq false }
  end

  context "permissions" do
    describe "case 1" do
      before { model.permission :action_module_items }
      it do
        expect(model.permission_names).to include "action_module_items"
        expect(model.module_permission_names).to have_key :module
        expect(model.module_permission_names[:module]).to include :action_module_items
      end

      it "separate_names" do
        permissions = model.module_permission_names
        permissions = model.separate_names(permissions)
        expect(permissions[:module]).to include :action_module_items
        expect(permissions[:gws]).to include :separator
      end
    end

    describe "case 2" do
      before { model.permission :action_module_item_names }
      it do
        expect(model.permission_names).to include "action_module_item_names"
        expect(model.module_permission_names).to have_key :module
        expect(model.module_permission_names[:module]).to include :action_module_item_names
      end
    end

    describe "case 3" do
      before { model.permission :action_module_name_items, module_name: "module_name" }
      it do
        expect(model.permission_names).to include "action_module_name_items"
        expect(model.module_permission_names).to have_key :module_name
        expect(model.module_permission_names[:module_name]).to include :action_module_name_items
      end
    end
  end
end
