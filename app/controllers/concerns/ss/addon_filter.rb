module SS::AddonFilter
  module Layout
    extend ActiveSupport::Concern
    include SS::LayoutFilter

    included do
      after_action :inherit_layout
    end

    def inherit_layout
      stylesheets.each do |path|
        controller.stylesheets << path unless controller.stylesheets.include?(path)
      end
      javascripts.each do |path|
        #ctrl = controller.is_a?(Cell::Rails) ? controller.controller : controller
        controller.javascripts << path unless controller.javascripts.include?(path)
      end
    end
  end

  module Edit
    extend ActiveSupport::Concern
    include SS::AgentFilter
    include SS::AddonFilter::Layout

    included do
      helper AddonHelper
      helper EditorHelper
    end

    public
      def show
        render partial: "show"
      end

      def new
        render partial: "form"
      end

      def create
        render partial: "form"
      end

      def edit
        render partial: "form"
      end

      def update
        render partial: "form"
      end
  end

  module View
    extend ActiveSupport::Concern
    include SS::AgentFilter

    included do
      helper EditorHelper
    end

    public
      def index
        render
      end
  end
end
