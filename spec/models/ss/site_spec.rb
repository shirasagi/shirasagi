require 'spec_helper'

describe SS::Site do
  describe "valid method" do
    it "normal item should be true" do
      item = build(:ss_site)
      item.valid?.should be_true
    end
    
    it "abnormal item should be false" do
      item = build(:ss_site)
      item.name = nil
      item.valid?.should be_false
    end
  end
  
  describe "save method" do
    it "normal item should be true" do
      item = build(:ss_site)
      item.save.should be_true
    end
    
    it "abnormal_item should be false" do
      item = build(:ss_site)
      item.name = nil
      item.save.should be_false
    end
  end

  describe "all method" do
    before do
      @items = SS::Site.all
    end
    
    it "items shoud be loaded" do
      @items.size.should_not be_nil
    end
  end

  describe "find metthod" do
    it "item shoud be loaded" do
      item = SS::Site.find 1
      item.attributes.size.should_not be_nil
    end
  end

  describe "referred method" do
    before(:all) do
      @item = SS::Site.find 1
    end
    it "item shoud do domain" do
      @item.domain.should_not be_nil
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
  end
end
