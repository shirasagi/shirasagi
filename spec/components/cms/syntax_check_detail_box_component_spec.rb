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

  it 'displays when errors are present' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('#errorSyntaxChecker')
    expect(page).to have_content(I18n.t('errors.messages.invalid_order_of_h'))
    expect(page).to have_content(I18n.t('errors.messages.invalid_kana_character'))
    expect(page).to have_css('.btn-auto-correct', count: 1)
  end

  it 'does not display when there are no errors' do
    render_inline described_class.new(syntax_checker: empty_syntax_checker)
    expect(page).not_to have_css('#errorSyntaxChecker')
  end

  it 'shows details' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_content(I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h'))
    expect(page).to have_content('詳細2')
  end

  it 'shows auto-correct button only when collector is present' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('.btn-auto-correct', count: 1)
  end

  it 'displays error code in <code> tag' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('code', text: 'E001')
    expect(page).to have_css('code', text: 'E002')
  end

  it 'displays id with .column-name class' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('.column-name', text: 'html')
    expect(page).to have_css('.column-name', text: 'body')
  end

  it 'shows detail even if it is a string' do
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

  it 'auto-correct button has correct attributes' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    btn = page.find('.btn-auto-correct')
    expect(btn[:type]).to eq 'submit'
    expect(btn[:name]).to eq 'auto_correct'
    expect(btn[:value]).to eq '0'
  end

  # エラーメッセージに対してツールチップが表示されることを確認するテスト
  it 'displays tooltip for error messages' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    expect(page).to have_css('.tooltip')
    expect(page).to have_css('.tooltip', count: 1) # エラー数分のツールチップが存在することを確認
  end

  # ツールチップ内にエラーの詳細情報が正しく表示されることを確認するテスト
  it 'shows error details in tooltip' do
    render_inline described_class.new(syntax_checker: syntax_checker)
    tooltips = page.all('.tooltip')

    # 最初のエラーのツールチップ内容を確認
    first_tooltip = tooltips.first
    expect(first_tooltip.find('.tooltip-content')).to have_content(I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h'))
    expect(first_tooltip.find('.tooltip-content')).to have_content('詳細2')

    # 2番目のエラーにはツールチップが表示されないことを確認（detailがないため）
    expect(page).to have_content(I18n.t('errors.messages.invalid_kana_character'))
    expect(page).not_to have_css('.tooltip', count: 2)
  end
end
