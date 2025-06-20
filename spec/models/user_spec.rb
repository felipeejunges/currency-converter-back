# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_length_of(:first_name).is_at_least(2).is_at_most(50) }
    it { should validate_length_of(:last_name).is_at_least(2).is_at_most(50) }
  end

  describe 'associations' do
    it { should have_many(:currency_conversions).dependent(:destroy) }
  end

  describe 'devise modules' do
    it 'includes the expected devise modules' do
      expect(User.devise_modules).to include(
        :database_authenticatable,
        :registerable,
        :recoverable,
        :rememberable,
        :validatable,
        :jwt_authenticatable
      )
    end
  end

  describe '#full_name' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

    it 'returns the full name' do
      expect(user.full_name).to eq('John Doe')
    end

    it 'strips extra whitespace' do
      user.first_name = '  John  '
      user.last_name = '  Doe  '
      expect(user.full_name).to eq('John Doe')
    end

    it 'handles empty names gracefully' do
      user.first_name = ''
      user.last_name = ''
      expect(user.full_name).to eq('')
    end
  end

  describe 'password validation' do
    it 'validates password length' do
      user = build(:user, password: '123', password_confirmation: '123')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end

    it 'validates password confirmation' do
      user = build(:user, password: 'password123', password_confirmation: 'different')
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end
  end

  describe 'email validation' do
    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'accepts valid email format' do
      user = build(:user, email: 'valid@example.com')
      expect(user).to be_valid
    end
  end

  describe 'name validations' do
    it 'validates first_name minimum length' do
      user = build(:user, first_name: 'A')
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include('is too short (minimum is 2 characters)')
    end

    it 'validates last_name minimum length' do
      user = build(:user, last_name: 'B')
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include('is too short (minimum is 2 characters)')
    end

    it 'validates first_name maximum length' do
      user = build(:user, first_name: 'A' * 51)
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include('is too long (maximum is 50 characters)')
    end

    it 'validates last_name maximum length' do
      user = build(:user, last_name: 'B' * 51)
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include('is too long (maximum is 50 characters)')
    end
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = create(:user)
      expect(user).to be_valid
      expect(user.first_name).to be_present
      expect(user.last_name).to be_present
      expect(user.email).to be_present
    end

    it 'generates unique emails' do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.email).not_to eq(user2.email)
    end
  end
end 
