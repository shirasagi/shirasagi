require 'spec_helper'

describe Cms::Layout do
  describe "valid method" do
    it "normal item should be true" do
      item = build(:cms_layout)
      item.valid?.should be_true
    end

    it "abnormal state should be false" do
      item = build(:cms_layout)
      item.state = nil
      item.valid?.should be_false
    end

    it "abnormal name should be false" do
      item = build(:cms_layout)
      item.name = nil
      item.valid?.should be_false
    end
  end

  describe "save method" do
    it "normal item should be true" do
      item = build(:cms_layout)
      item.save.should be_true
    end

    it "abnormal state should be false" do
      item = build(:cms_layout)
      item.state = nil
      item.save.should be_false
    end

    it "abnormal name should be false" do
      item = build(:cms_layout)
      item.name = nil
      item.save.should be_false
    end
  end

  describe "all method" do
    before do
      @items = Cms::Layout.all
    end

    it "items shoud be loaded" do
      @items.size.should_not be_nil
    end
  end

  describe "find metthod" do
    it "item shoud be loaded" do
      item = Cms::Layout.find 1
      item.attributes.size.should_not be_nil
    end
  end

  describe "referred method" do
    before(:all) do
      @item = Cms::Layout.find 1
    end
    it "item shoud do render_html" do
      @item.render_html.should_not be_nil
    end
    it "item shoud do render_json" do
      @item.render_json.should_not be_nil
    end
    it "item shoud do dirname" do
      @item.dirname.should be_nil
    end
    it "item shoud do basename" do
      @item.basename.should_not be_nil
    end
    it "item shoud do path" do
      @item.path.should_not be_nil
    end
    it "item shoud do url" do
      @item.url.should_not be_nil
    end
    it "item shoud do full_url" do
      @item.full_url.should_not be_nil
    end
    it "item shoud do json_path" do
      @item.json_path.should_not be_nil
    end
    it "item shoud do public?" do
      @item.public?.should_not be_nil
    end
    it "item shoud do node" do
      @item.node.should be_nil
    end
    it "item shoud do state_options" do
      @item.state_options.should_not be_nil
    end
  end
end
