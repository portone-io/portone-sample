require 'openssl'
require 'base64'
require 'time'
require 'json'
require 'active_support/security_utils'

module PortOneWebhook
  class WebhookVerificationError < StandardError; end
  class InvalidInputError < StandardError; end
  
  DEFAULT_TOLERANCE_IN_SECONDS = 5 * 60 # 5 minutes
  
  # Cache for processed secrets to avoid repeated base64 decoding
  @cache = {}
  @cache_mutex = Mutex.new
  
  def self.verify(secret, payload, headers, tolerance_in_seconds = DEFAULT_TOLERANCE_IN_SECONDS)
    # Validate inputs - match TypeScript error messages
    raise InvalidInputError, "Invalid secret" if secret.nil? || !secret.is_a?(String)
    raise InvalidInputError, "Invalid payload" if payload.nil? || !payload.is_a?(String)
    raise InvalidInputError, "Invalid headers" if headers.nil? || !headers.respond_to?(:[])
    
    # Extract required headers
    msg_id = headers['webhook-id']
    msg_signature = headers['webhook-signature']
    msg_timestamp = headers['webhook-timestamp']
    
    # Validate required headers exist - match TypeScript format
    if msg_id.nil? || msg_id.empty?
      raise WebhookVerificationError, "Missing required header: webhook-id"
    end
    
    if msg_signature.nil? || msg_signature.empty?
      raise WebhookVerificationError, "Missing required header: webhook-signature"
    end
    
    if msg_timestamp.nil? || msg_timestamp.empty?
      raise WebhookVerificationError, "Missing required header: webhook-timestamp"
    end
    
    # Get processed secret from cache or process it
    processed_secret = get_or_cache_secret(secret)
    
    # Verify timestamp
    verify_timestamp(msg_timestamp, tolerance_in_seconds)
    
    # Verify signature
    expected_signature = sign(processed_secret, msg_id, msg_timestamp, payload)
    
    # Extract signatures from header
    # Format: "v1,signature1 v1,signature2" (space-separated list of comma-separated version-signature pairs)
    passed_signatures = msg_signature.split(' ').map do |versioned_signature|
      version, signature = versioned_signature.split(',', 2)
      signature if version == 'v1' && signature
    end.compact
    
    if passed_signatures.empty?
      raise WebhookVerificationError, "No valid signatures found"
    end
    
    # Check if any signature matches using constant-time comparison
    signature_found = passed_signatures.any? do |signature|
      ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
    end
    
    unless signature_found
      raise WebhookVerificationError, "None of the given signatures match the expected signature"
    end
    
    # Parse and return the webhook data
    JSON.parse(payload)
  rescue JSON::ParserError => e
    raise WebhookVerificationError, "Invalid JSON payload: #{e.message}"
  end
  
  class << self
    private
    
    def get_or_cache_secret(secret)
      @cache_mutex.synchronize do
        return @cache[secret] if @cache.key?(secret)
        
        processed = process_secret(secret)
        @cache[secret] = processed
        processed
      end
    end
    
    def process_secret(secret)
      # Remove whsec_ prefix if present
      secret = secret.sub(/^whsec_/, '')
      
      # Decode base64 secret
      Base64.strict_decode64(secret)
    rescue ArgumentError => e
      raise InvalidInputError, "Invalid secret format: #{e.message}"
    end
    
    def verify_timestamp(timestamp_str, tolerance_in_seconds)
      begin
        timestamp = Integer(timestamp_str)
      rescue ArgumentError
        raise WebhookVerificationError, "Invalid timestamp format"
      end
      
      now = Time.now.to_i
      diff = now - timestamp
      
      if diff < -tolerance_in_seconds
        raise WebhookVerificationError, "Message timestamp too new"
      end
      
      if diff > tolerance_in_seconds
        raise WebhookVerificationError, "Message timestamp too old"
      end
    end
    
    def sign(secret, msg_id, msg_timestamp, payload)
      # Construct the signed content
      to_sign = "#{msg_id}.#{msg_timestamp}.#{payload}"
      
      # Generate HMAC-SHA256 signature
      digest = OpenSSL::Digest.new('SHA256')
      hmac = OpenSSL::HMAC.digest(digest, secret, to_sign)
      
      # Return base64 encoded signature
      Base64.strict_encode64(hmac)
    end
    
  end
end