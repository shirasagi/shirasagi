class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  def index
    respond_to do |format|
      format.html
      format.csv do
        filename = 'all_contents'
        filename = "#{filename}_#{Time.zone.now.to_i}.csv"
        response.status = 200
        send_enum Cms::AllContent.enum_csv(@cur_site),
                  type: 'text/csv; charset=Shift_JIS', filename: filename
      end
    end
  end
end
