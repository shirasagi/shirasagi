# coding: utf-8
module  Urgency::Nodes::Layout
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Urgency::Node::Layout
  end
  
  class ViewCell < Cell::Rails
    include Cells::Rails::ActionController
    include Cms::NodeFilter::ViewCell
    include Cms::ReleaseFilter::Page
    
    public
      def index
        page = Cms::Page.where(filename: /index.html$/, depth: @cur_node.depth).first
        raise "404" unless page
        raise "404" unless controller.class.to_s =~ /Preview/
        layout = Cms::Layout.find params[:layout].to_i rescue raise "404"
        
        controller.instance_variable_set :@cur_node, page
        controller.instance_variable_set :@cur_layout, layout
        render_page page
      end
  end
end
