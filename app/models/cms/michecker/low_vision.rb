class Cms::Michecker::LowVision
  include ActiveModel::Model
  include Cms::Michecker::Base

  def enum_csv(options)
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      # レベル
      drawer.column :severity
      # レベル（文字列）
      drawer.column :severityStr
      # 種類
      drawer.column :iconTooltip
      # WCAG 2.0
      drawer.column :evaluationItem_tableDataGuideline0 do
        drawer.body { |item| item.evaluationItem["tableDataGuideline"].try { |array| array[0] } }
      end
      # Section508
      drawer.column :evaluationItem_tableDataGuideline1 do
        drawer.body { |item| item.evaluationItem["tableDataGuideline"].try { |array| array[1] } }
      end
      # JIS
      drawer.column :evaluationItem_tableDataGuideline2 do
        drawer.body { |item| item.evaluationItem["tableDataGuideline"].try { |array| array[2] } }
      end
      # 深刻度
      drawer.column :severityLV
      # 前景色
      drawer.column :foreground
      # 背景色
      drawer.column :background
      # X座標
      drawer.column :x
      # Y座標
      drawer.column :y
      # 面積
      drawer.column :area
      # 達成方法
      drawer.column :evaluationItem_tableDataTechniques do
        drawer.body { |item| item.evaluationItem["tableDataTechniques"] }
      end
      # 内容
      drawer.column :description
    end

    drawer.enum(self.items, options.reverse_merge(model: self.class))
  end
end
