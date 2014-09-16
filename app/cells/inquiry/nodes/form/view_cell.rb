# coding: utf-8
module  Inquiry::Nodes::Form
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include SimpleCaptcha::ControllerHelpers

    before_action :set_columns, only: [:new, :confirm, :create, :sent]
    before_action :set_answer, only: [:new, :confirm, :create]

    public
      def new
        render file: "new"
      end

      def confirm
        if @answer.valid?
          render file: "confirm"
        else
          render file: "new"
        end
      end

      def create
        if params[:submit].present?
          if @cur_node.captcha_enabled?
            @answer.captcha = params[:answer].try(:[], :captcha)
            @answer.captcha_key = params[:answer].try(:[], :captcha_key)
            unless @answer.valid_with_captcha?
              return render file: "confirm"
            end
          end
          @answer.save
          if @cur_node.notify_mail_enabled?
            Inquiry::Mailer.notify_mail(@cur_site, @cur_node, @answer).deliver
          end
          if @cur_node.reply_mail_enabled?
            Inquiry::Mailer.reply_mail(@cur_site, @cur_node, @answer).try(:deliver)
          end
          controller.redirect_to "#{@cur_node.url}sent.html"
        else
          render file: "new"
        end
      end

      def sent
        render file: "sent"
      end

    private
      def set_columns
        @columns = Inquiry::Column.site(@cur_site).
          where(node_id: @cur_node.id, state: "public").
          order_by(order: 1)

        raise "404" if @columns.count == 0
      end

      def set_answer
        @items = []
        @data = {}
        @columns.each do |column|
          @items << [column, params[:item].try(:[], "#{column.id}")]
          @data[column.id] = params[:item].try(:[], "#{column.id}")
        end
        @answer = Inquiry::Answer.new(site_id: @cur_site.id, node_id: @cur_node.id)
        @answer.remote_addr = request.env["HTTP_X_REAL_IP"] || request.remote_ip
        @answer.user_agent = request.user_agent
        @answer.set_data(@data)
      end
  end
end
