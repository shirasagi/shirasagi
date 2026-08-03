module Guide::Addon
  module Procedure
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :link_url, type: String
      field :html, type: String
      field :procedure_location, type: String
      field :belongings, type: SS::Extensions::Lines
      field :procedure_applicant, type: SS::Extensions::Lines
      field :remarks, type: String

      permit_params :link_url
      permit_params :html
      permit_params :procedure_location
      permit_params :belongings
      permit_params :procedure_applicant
      permit_params :remarks
      permit_params :order

      validates :link_url, url: { absolute_path: true, allow_blank: true }

      template_variable_handler(:id, :template_variable_handler_name)
      template_variable_handler(:name, :template_variable_handler_name)
      template_variable_handler(:link_url, :template_variable_handler_link_url)
      template_variable_handler(:link, :template_variable_handler_link)
      template_variable_handler(:html, :template_variable_handler_html)
      template_variable_handler(:procedure_location, :template_variable_handler_name)
      template_variable_handler(:belongings, :template_variable_handler_name)
      template_variable_handler(:procedure_applicant, :template_variable_handler_name)
      template_variable_handler(:remarks, :template_variable_handler_name)

      liquidize do
        export :id
        export :name
        export :link_url do
          if link_url.present? && valid?
            link_url # CGI.escapeHTML が欲しい場合は escape_once を組み合わせる
          end
        end
        export :link do
          template_variable_handler_link("link", self)
        end
        export :html
        export :procedure_location
        export :belongings
        export :procedure_applicant
        export :remarks
      end
    end

    def template_variable_handler_name(name, issuer)
      ERB::Util.html_escape self.send(name)
    end

    def template_variable_handler_html(name, issuer)
      return nil unless respond_to?(name)
      self.send(name).present? ? self.send(name).html_safe : nil
    end

    def template_variable_handler_link(name, issuer)
      if link_url.present? && valid?
        ApplicationController.helpers.link_to(self.name, link_url)
      else
        self.name
      end
    end

    def template_variable_handler_link_url(name, issuer)
      if link_url.present? && valid?
        CGI.escapeHTML(link_url)
      end
    end

    def referenced_questions
      Guide::Question.site(@cur_site || site).node(@cur_node || node).where(
        edges: {
          "$elemMatch" => { point_ids: { "$in" => [id] } }
        }
      )
    end

    def necessary_count
      edges = Guide::Diagram::Edge.none
      referenced_questions.each do |question|
        edges += question.edges.in(point_ids: [id]).nin(optional_necessary_point_ids: [id])
      end
      edges.count
    end

    def optional_necessary_count
      edges = Guide::Diagram::Edge.none
      referenced_questions.each do |question|
        edges += question.edges.in(optional_necessary_point_ids: [id])
      end
      edges.count
    end
  end
end
