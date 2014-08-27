require 'spec_helper'

describe Sys::UsersController do

  before(:all) do
    build(:ss_user).save unless SS::User.exists?
  end

  before(:each) do
    @user = SS::User.where(_id: 1).first
    controller.stub(:logged_in?).and_return @user
  end

  it "should use UsersController" do
    controller.should be_an_instance_of(Sys::UsersController)
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
      get 'show', id: @user.id
      response.should be_success
    end

    it "Item should be loaded" do
      get 'show', id: @user.id
      assigns[:item].should == @user
    end
  end
end

