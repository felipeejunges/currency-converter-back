# frozen_string_literal: true

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
class Currency < ApplicationRecord
  has_many :from_currency_rates, class_name: 'CurrencyRate', foreign_key: 'from_currency_id', dependent: :destroy
  has_many :to_currency_rates, class_name: 'CurrencyRate', foreign_key: 'to_currency_id', dependent: :destroy

  validates :code, presence: true, uniqueness: true, length: { is: 3 }
  validates :name, presence: true
  validates :symbol, presence: true
  validates :symbol_native, presence: true

  scope :supported, -> { where(code: %w[BRL USD EUR JPY]) }

  def self.find_by_code(code)
    find_by(code: code.upcase)
  end

  def supported?
    %w[BRL USD EUR JPY].include?(code)
  end
end
