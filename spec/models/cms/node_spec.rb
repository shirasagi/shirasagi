require 'spec_helper'

describe Cms::Node do
  describe "valid method" do
    it "normal item should be true" do
      item = build(:cms_node)
      item.valid?.should be_true
    end
    
    it "abnormal state should be false" do
      item = build(:cms_node)
      item.state = nil
      item.valid?.should be_false
    end
    
    it "abnormal name should be false" do
      item = build(:cms_node)
      item.name = nil
      item.valid?.should be_false
    end
    
    it "abnormal filename should be false" do
      item = build(:cms_node)
      item.filename = nil
      item.valid?.should be_false
    end
    
    it "abnormal route should be false" do
      item = build(:cms_node)
      item.route = nil
      item.valid?.should be_false
    end
  end
  
  describe "save method" do
    it "normal item should be true" do
      item = build(:cms_node)
      item.save.should be_true
    end
    
    it "abnormal state should be false" do
      item = build(:cms_node)
      item.state = nil
      item.save.should be_false
    end
    
    it "abnormal name should be false" do
      item = build(:cms_node)
      item.name = nil
      item.save.should be_false
    end
    
    it "abnormal filename should be false" do
      item = build(:cms_node)
      item.filename = nil
      item.save.should be_false
    end
    
    it "abnormal route should be false" do
      item = build(:cms_node)
      item.route = nil
      item.save.should be_false
    end
  end

  describe "all method" do
    before do
      @items = Cms::Node.all
    end
    
    it "items shoud be loaded" do
      @items.size.should_not be_nil
    end
  end

  describe "find metthod" do
    it "item shoud be loaded" do
      item = Cms::Node.find 1
      item.attributes.size.should_not be_nil
    end
  end

  describe "referred method" do
    before(:all) do
      @item = Cms::Node.find_by depth: 2
    end
    it "item shoud do becomes_with_route" do
      @item.becomes_with_route.should_not be_nil
    end
    it "item shoud do dirname" do
      @item.dirname.should_not be_nil
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
    it "item shoud do public?" do
      @item.public?.should_not be_nil
    end
    it "item shoud do date" do
      @item.date.should_not be_nil
    end
    it "item shoud do parents" do
      @item.parents.should_not be_nil
    end
    it "item shoud do parent" do
      @item.parent.should_not be_nil
    end
    it "item shoud do nodes" do
      @item.nodes.should_not be_nil
    end
    it "item shoud do children" do
      @item.children.should_not be_nil
    end
    it "item shoud do pages" do
      @item.pages.should_not be_nil
    end
    it "item shoud do parts" do
      @item.parts.should_not be_nil
    end
    it "item shoud do layouts" do
      @item.layouts.should_not be_nil
    end
    it "item shoud do route_options" do
      @item.route_options.should_not be_nil
    end
    it "item shoud do state_options" do
      @item.state_options.should_not be_nil
    end
    it "item shoud do shortcut_options" do
      @item.shortcut_options.should_not be_nil
    end
  end
end
