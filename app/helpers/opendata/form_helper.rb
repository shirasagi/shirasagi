module Opendata::FormHelper
  def required_label
    %(<div style="color: #e00;">&lt;必須入力&gt;</div>).html_safe
  end
end
