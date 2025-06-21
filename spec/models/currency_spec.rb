# == Schema Information
#
# Table name: currencies
#
#  id            :bigint           not null, primary key
#  code          :string           not null
#  name          :string           not null
#  symbol        :string           not null
#  symbol_native :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_currencies_on_code  (code) UNIQUE
#
require 'rails_helper'

RSpec.describe Currency, type: :model do
  describe 'validations' do
    subject { build(:currency, :usd) }

    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:symbol) }
    it { should validate_presence_of(:symbol_native) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_length_of(:code).is_equal_to(3) }
  end

  describe 'associations' do
    it { should have_many(:from_currency_rates).class_name('CurrencyRate').with_foreign_key('from_currency_id') }
    it { should have_many(:to_currency_rates).class_name('CurrencyRate').with_foreign_key('to_currency_id') }
  end

  describe 'scopes' do
    let!(:usd) { create(:currency, :usd) }
    let!(:brl) { create(:currency, :brl) }
    let!(:eur) { create(:currency, :eur) }
    let!(:jpy) { create(:currency, :jpy) }

    describe '.supported' do
      it 'returns only supported currencies' do
        expect(Currency.supported).to contain_exactly(usd, brl, eur, jpy)
      end
    end
  end

  describe '.find_by_code' do
    let!(:currency) { create(:currency, :usd) }

    it 'finds currency by code case insensitive' do
      expect(Currency.find_by_code('usd')).to eq(currency)
      expect(Currency.find_by_code('USD')).to eq(currency)
    end
  end

  describe '#supported?' do
    it 'returns true for supported currencies' do
      %w[BRL USD EUR JPY].each do |code|
        currency = build(:currency, :usd)
        currency.code = code
        expect(currency.supported?).to be true
      end
    end

    it 'returns false for unsupported currencies' do
      currency = build(:currency, :usd)
      currency.code = 'GBP'
      expect(currency.supported?).to be false
    end
  end
end 
