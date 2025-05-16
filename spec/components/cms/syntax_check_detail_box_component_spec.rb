require 'spec_helper'

RSpec.describe Cms::SyntaxCheckDetailBoxComponent, type: :component do
  let(:errors) do
    [
      {
        id: 'html',
        code: 'E001',
        msg: I18n.t('errors.messages.invalid_order_of_h'),
        detail: [I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h'), '詳細2'],
        collector: 'test_collector'
      },
      {
        id: 'body',
        code: 'E002',
        msg: I18n.t('errors.messages.invalid_kana_character'),
        collector: nil
      }
    ]
  end

  let(:syntax_checker) { double('SyntaxChecker', errors: errors) }
  let(:empty_syntax_checker) { double('SyntaxChecker', errors: []) }

  it 'エラーがある場合に表示される' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('#errorSyntaxChecker')
    expect(page).to have_content(I18n.t('errors.messages.invalid_order_of_h'))
    expect(page).to have_content(I18n.t('errors.messages.invalid_kana_character'))
    expect(page).to have_css('.btn-auto-correct', count: 1)
  end

  it 'エラーがない場合は表示されない' do
    render_inline described_class.new(syntax_checker: empty_syntax_checker)
    expect(page).not_to have_css('#errorSyntaxChecker')
  end

  it '詳細が表示される' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_content(I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h'))
    expect(page).to have_content('詳細2')
  end

  it '自動修正ボタンがcollectorがある場合のみ表示される' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('.btn-auto-correct', count: 1)
  end

  it 'エラーコードが<code>タグで表示される' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('code', text: 'E001')
    expect(page).to have_css('code', text: 'E002')
  end

  it 'idが.column-nameクラスで表示される' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('.column-name', text: 'html')
    expect(page).to have_css('.column-name', text: 'body')
  end

  it 'detailが文字列でも表示される' do
    errors = [
      {
        id: 'html',
        code: 'E001',
        msg: I18n.t('errors.messages.invalid_order_of_h'),
        detail: Array(I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')).first,
        collector: 'test_collector'
      }
    ]
    syntax_checker = double('SyntaxChecker', errors: errors)
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('li', text: Array(I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')).first)
  end

  it '自動修正ボタンの属性が正しい' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    btn = page.find('.btn-auto-correct')
    expect(btn[:type]).to eq 'submit'
    expect(btn[:name]).to eq 'auto_correct'
    expect(btn[:value]).to eq '0'
  end
end
