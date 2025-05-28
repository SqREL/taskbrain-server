# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/security_utils'

RSpec.describe SecurityUtils do
  before do
    # Set a test encryption key
    ENV['ENCRYPTION_KEY'] = 'kLFG+u/1SOVaoIpld0MzUJoO81uhBLsz8zXCNiIhDW4='
  end

  describe '.encryption_key' do
    it 'returns the encryption key from environment' do
      key = described_class.encryption_key
      expect(key).to be_a(String)
      expect(key.length).to eq(32) # 32 bytes for AES-256
    end

    context 'when ENCRYPTION_KEY is not set' do
      before do
        ENV['ENCRYPTION_KEY'] = nil
        # Reset the memoized key
        described_class.instance_variable_set(:@encryption_key, nil)
      end

      after do
        ENV['ENCRYPTION_KEY'] = 'kLFG+u/1SOVaoIpld0MzUJoO81uhBLsz8zXCNiIhDW4='
      end

      it 'generates a new key and warns user' do
        expect { described_class.encryption_key }.to output(/Generated new encryption key/).to_stdout
      end
    end
  end

  describe '.encrypt and .decrypt' do
    let(:test_data) { 'sensitive_token_data_12345' }

    it 'encrypts and decrypts data correctly' do
      encrypted = described_class.encrypt(test_data)
      expect(encrypted).not_to eq(test_data)
      expect(encrypted).to be_a(String)

      decrypted = described_class.decrypt(encrypted)
      expect(decrypted).to eq(test_data)
    end

    it 'returns different encrypted values for same input' do
      encrypted1 = described_class.encrypt(test_data)
      encrypted2 = described_class.encrypt(test_data)
      expect(encrypted1).not_to eq(encrypted2)

      # But both should decrypt to the same value
      expect(described_class.decrypt(encrypted1)).to eq(test_data)
      expect(described_class.decrypt(encrypted2)).to eq(test_data)
    end

    it 'handles nil input gracefully' do
      expect(described_class.encrypt(nil)).to be_nil
      expect(described_class.decrypt(nil)).to be_nil
    end

    it 'handles empty string input' do
      expect(described_class.encrypt('')).to eq('')
      expect(described_class.decrypt('')).to be_nil
    end

    it 'returns nil for invalid encrypted data' do
      expect(described_class.decrypt('invalid_encrypted_data')).to be_nil
    end

    it 'encrypts non-string data by converting to string' do
      number_data = 12_345
      encrypted = described_class.encrypt(number_data)
      decrypted = described_class.decrypt(encrypted)
      expect(decrypted).to eq('12345')
    end
  end

  describe '.secure_store_token and .secure_get_token' do
    let(:mock_redis) { double('Redis') }
    let(:token) { 'access_token_12345' }
    let(:key) { 'test_token_key' }

    it 'stores and retrieves tokens securely' do
      # Mock Redis to capture the encrypted token
      stored_token = nil
      
      expect(mock_redis).to receive(:setex) do |k, ttl, enc_token|
        expect(k).to eq(key)
        expect(ttl).to eq(3600)
        stored_token = enc_token
      end
      
      described_class.secure_store_token(mock_redis, key, token)
      
      # Return the same encrypted token that was stored
      expect(mock_redis).to receive(:get).with(key).and_return(stored_token)
      retrieved_token = described_class.secure_get_token(mock_redis, key)

      expect(retrieved_token).to eq(token)
    end

    it 'uses custom TTL when provided' do
      custom_ttl = 7200

      expect(mock_redis).to receive(:setex).with(key, custom_ttl, anything)
      described_class.secure_store_token(mock_redis, key, token, custom_ttl)
    end

    it 'returns nil when token not found in Redis' do
      expect(mock_redis).to receive(:get).with(key).and_return(nil)
      result = described_class.secure_get_token(mock_redis, key)
      expect(result).to be_nil
    end

    it 'returns nil when encrypted token is corrupted' do
      expect(mock_redis).to receive(:get).with(key).and_return('corrupted_data')
      result = described_class.secure_get_token(mock_redis, key)
      expect(result).to be_nil
    end
  end

  describe '.hash_api_key' do
    let(:api_key) { 'test_api_key_123' }

    it 'generates consistent hash for same API key' do
      hash1 = described_class.hash_api_key(api_key)
      hash2 = described_class.hash_api_key(api_key)
      expect(hash1).to eq(hash2)
    end

    it 'generates different hashes for different API keys' do
      hash1 = described_class.hash_api_key('key1')
      hash2 = described_class.hash_api_key('key2')
      expect(hash1).not_to eq(hash2)
    end

    it 'returns 32-byte hash' do
      hash = described_class.hash_api_key(api_key)
      expect(hash.length).to eq(32)
    end

    context 'with custom salt' do
      before do
        ENV['API_KEY_SALT'] = 'custom_salt_123'
      end

      after do
        ENV['API_KEY_SALT'] = nil
      end

      it 'uses custom salt from environment' do
        hash_with_salt = described_class.hash_api_key(api_key)

        # Temporarily remove custom salt
        ENV['API_KEY_SALT'] = nil
        hash_without_salt = described_class.hash_api_key(api_key)

        expect(hash_with_salt).not_to eq(hash_without_salt)
      end
    end
  end

  describe '.generate_secure_token' do
    it 'generates secure random token' do
      token = described_class.generate_secure_token
      expect(token).to be_a(String)
      expect(token.length).to be > 30 # URL-safe base64 encoding
    end

    it 'generates different tokens each time' do
      token1 = described_class.generate_secure_token
      token2 = described_class.generate_secure_token
      expect(token1).not_to eq(token2)
    end

    it 'accepts custom length' do
      short_token = described_class.generate_secure_token(16)
      long_token = described_class.generate_secure_token(64)
      expect(short_token.length).to be < long_token.length
    end

    it 'generates URL-safe tokens' do
      token = described_class.generate_secure_token
      expect(token).to match(/\A[A-Za-z0-9_-]+\z/)
    end
  end

  describe 'encryption algorithm security' do
    let(:test_data) { 'sensitive_data' }

    it 'uses AES-256-GCM encryption' do
      encrypted = described_class.encrypt(test_data)

      # Decode and check structure
      combined = Base64.strict_decode64(encrypted)
      expect(combined.length).to be >= 28 # IV (12) + auth_tag (16) + at least some encrypted data

      # IV should be 12 bytes
      iv = combined[0, 12]
      expect(iv.length).to eq(12)

      # Auth tag should be 16 bytes
      auth_tag = combined[12, 16]
      expect(auth_tag.length).to eq(16)
    end

    it 'includes authentication tag for integrity' do
      encrypted = described_class.encrypt(test_data)

      # Decode the encrypted data
      combined = Base64.strict_decode64(encrypted)
      
      # Tamper with the auth tag portion (bytes 12-27)
      tampered_combined = combined.dup
      tampered_combined[12] = (tampered_combined[12].ord ^ 0xFF).chr
      
      # Re-encode
      tampered = Base64.strict_encode64(tampered_combined)

      # Should fail to decrypt tampered data due to auth tag mismatch
      expect(described_class.decrypt(tampered)).to be_nil
    end

    it 'uses random IV for each encryption' do
      encrypted1 = described_class.encrypt(test_data)
      encrypted2 = described_class.encrypt(test_data)

      combined1 = Base64.strict_decode64(encrypted1)
      combined2 = Base64.strict_decode64(encrypted2)

      iv1 = combined1[0, 12]
      iv2 = combined2[0, 12]

      expect(iv1).not_to eq(iv2)
    end
  end
end
