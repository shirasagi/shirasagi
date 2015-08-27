class Sns::MypageController < ApplicationController
  include Sns::BaseFilter

  public
    def index
      @sites = []
      SS::Site.each do |site|
        if @cur_user.groups.in(name: site.groups.pluck(:name).map{ |name| /^#{Regexp.escape(name)}(\/|$)/ } ).present?
          @sites << site
        end
      end

      ids = @cur_user.groups.map { |group| group.root.try(:id) }.uniq.compact
      @groups = SS::Group.where(:id.in => ids).all
    end
end
