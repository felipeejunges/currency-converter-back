# == Schema Information
#
# Table name: currency_rates
#
#  id               :bigint           not null, primary key
#  fetched_at       :datetime         not null
#  rate             :decimal(20, 10)  not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  from_currency_id :bigint           not null
#  to_currency_id   :bigint           not null
#
# Indexes
#
#  index_currency_rates_on_fetched_at        (fetched_at)
#  index_currency_rates_on_from_currency_id  (from_currency_id)
#  index_currency_rates_on_to_currency_id    (to_currency_id)
#
# Foreign Keys
#
#  fk_rails_...  (from_currency_id => currencies.id)
#  fk_rails_...  (to_currency_id => currencies.id)
#
require 'rails_helper'

RSpec.describe CurrencyRate, type: :model do
  describe 'validations' do
    subject { build(:currency_rate) }

    it { should validate_presence_of(:rate) }
    it { should validate_presence_of(:fetched_at) }
    it { should validate_numericality_of(:rate).is_greater_than(0) }
  end

  describe 'associations' do
    it { should belong_to(:from_currency).class_name('Currency') }
    it { should belong_to(:to_currency).class_name('Currency') }
    it { should have_many(:currency_conversions).class_name('Currency::Conversion').dependent(:destroy) }
  end

  describe 'scopes' do
    let(:usd_currency) { create(:currency, :usd) }
    let(:brl_currency) { create(:currency, :brl) }
    let(:eur_currency) { create(:currency, :eur) }
    let(:jpy_currency) { create(:currency, :jpy) }
    
    let!(:old_rate) { create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, fetched_at: 2.days.ago) }
    let!(:new_rate) { create(:currency_rate, from_currency: eur_currency, to_currency: jpy_currency, fetched_at: 1.day.ago, rate: 150.0) }
    let!(:today_rate) { create(:currency_rate, from_currency: jpy_currency, to_currency: eur_currency, fetched_at: Time.current, rate: 0.0067) }

    describe '.recent' do
      it 'orders by fetched_at descending' do
        expect(CurrencyRate.recent).to eq([today_rate, new_rate, old_rate])
      end
    end

    describe '.today' do
      it 'returns only rates fetched today' do
        expect(CurrencyRate.today).to contain_exactly(today_rate)
      end
    end
  end

  describe '.latest_for' do
    let(:from_currency) { create(:currency, :usd) }
    let(:to_currency) { create(:currency, :brl) }
    let!(:old_rate) { create(:currency_rate, from_currency: from_currency, to_currency: to_currency, fetched_at: 2.days.ago) }
    let!(:new_rate) { create(:currency_rate, from_currency: from_currency, to_currency: to_currency, fetched_at: 1.day.ago) }

    it 'returns the most recent rate' do
      expect(CurrencyRate.latest_for(from_currency, to_currency)).to eq(new_rate)
    end
  end

  describe '.create_or_update_rate' do
    let(:from_currency) { create(:currency, :usd) }
    let(:to_currency) { create(:currency, :brl) }
    let(:rate) { 5.25 }

    context 'when rate does not exist' do
      it 'creates a new rate' do
        expect {
          CurrencyRate.create_or_update_rate(from_currency, to_currency, rate)
        }.to change(CurrencyRate, :count).by(1)
      end
    end

    context 'when rate already exists' do
      let!(:existing_rate) { create(:currency_rate, from_currency: from_currency, to_currency: to_currency, rate: 4.0) }

      it 'updates the existing rate' do
        expect {
          CurrencyRate.create_or_update_rate(from_currency, to_currency, rate)
        }.not_to change(CurrencyRate, :count)

        existing_rate.reload
        expect(existing_rate.rate).to eq(rate)
      end
    end
  end

  describe '#inverse_rate' do
    let(:currency_rate) { build(:currency_rate, rate: 5.0) }

    it 'returns the inverse of the rate' do
      expect(currency_rate.inverse_rate).to eq(0.2)
    end

    context 'when rate is zero' do
      let(:currency_rate) { build(:currency_rate, rate: 0) }

      it 'returns nil' do
        expect(currency_rate.inverse_rate).to be_nil
      end
    end
  end
end 
