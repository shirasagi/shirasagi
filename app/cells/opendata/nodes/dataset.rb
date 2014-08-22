# coding: utf-8
module Opendata::Nodes::Dataset
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Dataset
  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    before_action :logged_in?

    public
      def index
        @items = Opendata::Dataset.site(@cur_site).
          order_by(updated: -1).
          page(params[:page]).
          per(20)

        @items.empty? ? "" : render
      end

      def show
        @model = Opendata::Dataset
        @item = @model.site(@cur_site).find(params[:id])

        @in = Array.new(0, nil)
        @item.file_ids.each do |file|
          @in.push(file)
        end
        @filemodel = Opendata::DatasetFile
        @file = @filemodel.where(:id => @in)

        render
      end

      def new
        @model = Opendata::Dataset
        @item = @model.new
        @filemodel = Opendata::DatasetFile
        @file = @filemodel.new
        #5.times do
          #@item.files = Opendata::DatasetFile.new
        #end
        render
      end

      def create
        if params[:submit].present?
          @filemodel = Opendata::DatasetFile
          @file = @filemodel.new get_fileparams

          @model = Opendata::Dataset
          @item = @model.new get_params
          @item.user_id = @cur_user.id
          @item.site_id = @cur_site.id
          #@item.group_id = params[:group_id]
          @file.in_files.each do |f|
            file = @filemodel.new
            file.in_file = f
            if file.save
              @item.file_ids = Array.new(5, file._id.to_s)
              #@item.file_ids << file._id.to_s
            else
              controller.redirect_to "#{@cur_node.url}new.html"
            end
          end
          #raise @item.file_ids.to_s
          if @item.save
            controller.redirect_to "#{@cur_node.url}"
          else
            controller.redirect_to "#{@cur_node.url}new.html"
          end
        else
          controller.redirect_to "#{@cur_node.url}"
        end
      end

      def file
       #cond = (@cur_user.id != @sns_user.id) ? { state: :public } : { }

        @model = Opendata::DatasetFile
        @item = @model.new
        render
      end

      def upload
        @model = Opendata::DatasetFile
        @item = @model.new get_fileparams
        if @item.save_files
          controller.redirect_to "#{@cur_node.url}"
        else
          controller.redirect_to "#{@cur_node.url}file.html"
        end
      end

    private
      def get_params
        #params.require(:item).permit(:id, :state, :name, :categry_ids, :point, :text, :license)
        #params.require(:item).permit(:id, :state, :name, :categry_ids, :point, :text, :license, files_attributes: [:dataset_id])
        params.require(:item).permit(permit_fields).merge(fix_params)
      end

      def get_fileparams
        params.require(:file).permit(permit_file_fields).merge(fix_params)
      end

      def fix_params
        { cur_user: @cur_user }
      end

      def permit_fields
        @model.permitted_fields
      end

      def permit_file_fields
        @filemodel.permitted_fields
      end

      def logged_in?
        return @cur_user if @cur_user

        if session[:user]
          u = SS::Crypt.decrypt(session[:user]).to_s.split(",", 3)
          return unset_user redirect: true if u[1] != remote_addr
          return unset_user redirect: true if u[2] != request.user_agent
          @cur_user = SS::User.find u[0].to_i rescue nil
        end

        return @cur_user if @cur_user
        unset_user

        ref = request.env["REQUEST_URI"]
        ref = (ref == "http://#{request.host}:#{request.port.to_s}") ? "" : "?ref=" + CGI.escape(ref.to_s)
        controller.redirect_to "http://#{request.host}:#{request.port.to_s}user"
      end

      def set_user(user, opt = {})
        if opt[:session]
          session[:user] = SS::Crypt.encrypt("#{user._id},#{remote_addr},#{request.user_agent}")
        end
        controller.redirect_to "http://#{request.host}:#{request.port.to_s}" if opt[:redirect]
        @cur_user = user
      end

      def unset_user(opt = {})
        session[:user] = nil
        controller.redirect_to "http://#{request.host}:#{request.port.to_s}user" if opt[:redirect]
        @cur_user = nil
      end

      def remote_addr
        request.env["HTTP_X_REAL_IP"] || request.remote_addr
      end
  end
end
