class Sns::MypageController < ApplicationController
  include Sns::BaseFilter

  public
    def index
      #mypage

      @sites = []
      SS::Site.each do |site|
        if @cur_user.groups.in(name: site.groups.pluck(:name).map{ |name| /^#{name}(\/|$)/ } ).present?
          @sites << site
        end
      end
    end
end
