require 'spec_helper'

describe Cms::NodeHelper, type: :helper, dbscope: :example do
  let(:site) { cms_site }
  let!(:node) do
    create(:article_node_page, cur_site: site)
  end

  describe "#cms_syntax_check_enabled?" do
    let(:default_check_logic) do
      proc do |site, node|
        syntax_check = true
        syntax_check = site.syntax_check_enabled? if syntax_check
        if node && node.respond_to?(:syntax_check_enabled?)
          syntax_check = node.syntax_check_enabled? if syntax_check
        end
        syntax_check
      end
    end

    context "both on site and node is enabled" do
      before do
        site.syntax_check = "enabled"
        site.save!

        node.syntax_check = "enabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_truthy
        expect(helper.cms_syntax_check_enabled?).to be_truthy
      end
    end

    context "syntax check is enabled on site, but is disabled on node" do
      before do
        site.syntax_check = "enabled"
        site.save!

        node.syntax_check = "disabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_falsey
        expect(helper.cms_syntax_check_enabled?).to be_falsey
      end
    end

    context "syntax check is disabled on site, but is enabled on node" do
      before do
        site.syntax_check = "disabled"
        site.save!

        node.syntax_check = "enabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_falsey
        expect(helper.cms_syntax_check_enabled?).to be_falsey
      end
    end

    context "both on site and node is disabled" do
      before do
        site.syntax_check = "disabled"
        site.save!

        node.syntax_check = "disabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_falsey
        expect(helper.cms_syntax_check_enabled?).to be_falsey
      end
    end

    context "with column" do
      let!(:item) { create :article_page, cur_site: site, cur_node: node }
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, order: 1) }
      let(:default_check_logic) do
        proc do |site, node, column, item|
          inplace_syntax_check = column.syntax_check_enabled?
          inplace_syntax_check = site.syntax_check_enabled? if inplace_syntax_check
          inplace_syntax_check = node.syntax_check_enabled? if inplace_syntax_check && node
          if node && node.respond_to?(:syntax_check_enabled?)
            inplace_syntax_check = node.syntax_check_enabled? if inplace_syntax_check
          end
          if item.parent && item.parent.respond_to?(:syntax_check_enabled?)
            inplace_syntax_check = item.parent.syntax_check_enabled? if inplace_syntax_check
          end
          inplace_syntax_check
        end
      end

      context "both on site and node is enabled" do
        before do
          site.syntax_check = "enabled"
          site.save!

          node.syntax_check = "enabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node
          @cur_column = column
          @item = item

          expect(default_check_logic.call(site, node, column, item)).to be_truthy
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_truthy
        end
      end

      context "syntax check is enabled on site, but is disabled on node" do
        before do
          site.syntax_check = "enabled"
          site.save!

          node.syntax_check = "disabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node
          @cur_column = column
          @item = item

          expect(default_check_logic.call(site, node, column, item)).to be_falsey
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_falsey
        end
      end

      context "syntax check is disabled on site, but is enabled on node" do
        before do
          site.syntax_check = "disabled"
          site.save!

          node.syntax_check = "enabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node

          expect(default_check_logic.call(site, node, column, item)).to be_falsey
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_falsey
        end
      end

      context "both on site and node is disabled" do
        before do
          site.syntax_check = "disabled"
          site.save!

          node.syntax_check = "disabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node

          expect(default_check_logic.call(site, node, column, item)).to be_falsey
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_falsey
        end
      end
    end
  end
end
