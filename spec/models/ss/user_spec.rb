require 'spec_helper'

describe SS::User do
  describe "valid method" do
    it "normal item should be true" do
      item = build(:ss_user)
      item.valid?.should be_true
    end
    
    it "abnormal item should be false" do
      item = build(:ss_user)
      item.email = nil
      item.valid?.should be_false
    end
  end
  
  describe "save method" do
    it "normal item should be true" do
      item = build(:ss_user)
      item.save.should be_true
    end
    
    it "abnormal_item should be false" do
      item = build(:ss_user)
      item.email = nil
      item.save.should be_false
    end
  end

  describe "all method" do
    before do
      @items = SS::User.all
    end
    
    it "items shoud be loaded" do
      @items.size.should_not be_nil
    end
  end

  describe "find metthod" do
    it "item shoud be loaded" do
      item = SS::User.find 1
      item.attributes.size.should_not be_nil
    end
  end
end
