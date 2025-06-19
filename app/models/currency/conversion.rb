# frozen_string_literal: true

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
class Currency::Conversion < ApplicationRecord # rubocop:disable Style/ClassAndModuleChildren
  belongs_to :currency_rate
  belongs_to :user
  delegate :from_currency, :to_currency, to: :currency_rate

  validates :from_value, presence: true, numericality: { greater_than: 0 }
  validates :to_value, presence: true, numericality: { greater_than: 0 }
  validates :currency_rate, presence: true
  validates :user, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  before_create :log_conversion

  def rate
    currency_rate.rate
  end

  def from_currency_code
    from_currency.code
  end

  def to_currency_code
    to_currency.code
  end

  def timestamp
    created_at
  end

    private

  def log_conversion
    Rails.logger.info(
      "Currency conversion: #{from_value} #{from_currency_code} -> #{to_value} #{to_currency_code} " \
      "(Rate: #{rate}, User: #{user_id}, Force refresh: #{force_refresh})"
    )
  end
end
