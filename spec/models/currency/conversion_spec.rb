# == Schema Information
#
# Table name: currency_conversions
#
#  id               :bigint           not null, primary key
#  force_refresh    :boolean          default(FALSE)
#  from_value       :decimal(20, 10)  not null
#  to_value         :decimal(20, 10)  not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  currency_rate_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_currency_conversions_on_currency_rate_id        (currency_rate_id)
#  index_currency_conversions_on_user_id                 (user_id)
#  index_currency_conversions_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (currency_rate_id => currency_rates.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Currency::Conversion, type: :model do
  describe 'validations' do
    subject { build(:currency_conversion) }

    it { should validate_presence_of(:from_value) }
    it { should validate_presence_of(:to_value) }
    it { should validate_presence_of(:currency_rate) }
    it { should validate_presence_of(:user) }
    it { should validate_numericality_of(:from_value).is_greater_than(0) }
    it { should validate_numericality_of(:to_value).is_greater_than(0) }
  end

  describe 'associations' do
    it { should belong_to(:currency_rate) }
    it { should belong_to(:user) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    
    let(:usd_currency) { create(:currency, :usd) }
    let(:brl_currency) { create(:currency, :brl) }
    let(:eur_currency) { create(:currency, :eur) }
    let(:jpy_currency) { create(:currency, :jpy) }
  
    let(:rate1) { create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency) }
    let(:rate2) { create(:currency_rate, from_currency: eur_currency, to_currency: jpy_currency, rate: 150.0) }
    let(:rate3) { create(:currency_rate, from_currency: brl_currency, to_currency: usd_currency, rate: 0.19) }
    
    let!(:user_conversion) { create(:currency_conversion, currency_rate: rate1, user: user) }
    let!(:other_conversion) { create(:currency_conversion, currency_rate: rate2, user: other_user, from_value: 50.0, to_value: 7500.0) }

    describe '.for_user' do
      it 'returns conversions for the specified user' do
        expect(Currency::Conversion.for_user(user)).to contain_exactly(user_conversion)
      end
    end

    describe '.recent' do
      let(:recent_user) { create(:user) }
      let!(:old_conversion) { create(:currency_conversion, currency_rate: rate3, user: recent_user, created_at: 2.days.ago, from_value: 200.0, to_value: 38.0) }
      let!(:new_conversion) { create(:currency_conversion, currency_rate: rate2, user: recent_user, created_at: 1.day.ago, from_value: 25.0, to_value: 3750.0) }

      it 'orders by created_at descending' do
        expect(Currency::Conversion.for_user(recent_user).recent).to eq([new_conversion, old_conversion])
      end
    end
  end

  describe 'delegations' do
    let(:currency_rate) { create(:currency_rate) }
    let(:conversion) { build(:currency_conversion, currency_rate: currency_rate) }

    it 'delegates from_currency to currency_rate' do
      expect(conversion.from_currency).to eq(currency_rate.from_currency)
    end

    it 'delegates to_currency to currency_rate' do
      expect(conversion.to_currency).to eq(currency_rate.to_currency)
    end
  end

  describe '#rate' do
    let(:currency_rate) { create(:currency_rate, rate: 5.25) }
    let(:conversion) { build(:currency_conversion, currency_rate: currency_rate) }

    it 'returns the rate from currency_rate' do
      expect(conversion.rate).to eq(5.25)
    end
  end

  describe '#from_currency_code' do
    let(:from_currency) { create(:currency, :usd) }
    let(:currency_rate) { create(:currency_rate, from_currency: from_currency) }
    let(:conversion) { build(:currency_conversion, currency_rate: currency_rate) }

    it 'returns the from currency code' do
      expect(conversion.from_currency_code).to eq('USD')
    end
  end

  describe '#to_currency_code' do
    let(:to_currency) { create(:currency, :brl) }
    let(:currency_rate) { create(:currency_rate, to_currency: to_currency) }
    let(:conversion) { build(:currency_conversion, currency_rate: currency_rate) }

    it 'returns the to currency code' do
      expect(conversion.to_currency_code).to eq('BRL')
    end
  end

  describe '#timestamp' do
    let(:conversion) { build(:currency_conversion) }

    it 'returns the created_at timestamp' do
      expect(conversion.timestamp).to eq(conversion.created_at)
    end
  end

  describe 'logging' do
    let(:conversion) { build(:currency_conversion) }

    it 'logs conversion on create' do
      expect(Rails.logger).to receive(:info).with(/Currency conversion:/)
      conversion.save!
    end
  end
end 
