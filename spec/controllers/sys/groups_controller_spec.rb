require 'spec_helper'

=begin
describe Sys::GroupsController do

  before(:all) do
    build(:ss_group).save unless SS::Group.exists?
    build(:ss_user).save unless SS::User.exists?
  end

  before(:each) do
#    @cur_user = create(:ss_user)
    @cur_user = SS::User.where(_id: 1).first
    controller.stub(:logged_in?).and_return @cur_user
    @group = SS::Group.where(_id: 1).first
  end

  it "should use GroupsController" do
    controller.should be_an_instance_of(Sys::GroupsController)
  end

  describe "GET 'INDEX'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end

    it "Items should be loaded" do
      get 'index'
      assigns[:items].size.should_not be_nil
    end
  end

  describe "GET 'SHOW'" do
    it "should be successful" do
      get 'show', id: @group.id
      response.should be_success
    end

    it "Item should be loaded" do
      get 'show', id: @group.id
      assigns[:item].should == @group
    end
  end
end
=end
