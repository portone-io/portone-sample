require 'faraday'
require 'json'
require_relative '../lib/portone_webhook_verifier'

class PaymentController < ApplicationController
  # Rails convention: disable CSRF for API endpoints
  skip_before_action :verify_authenticity_token, only: [:complete, :webhook]
  
  # In-memory payment store (like Express Map)
  @@payment_store = {}
  
  # Single hardcoded item (like Express sample)
  ITEM = {
    id: 'shoes',
    name: '신발', 
    price: 1000,
    currency: 'KRW'
  }.freeze
  
  # GET /api/item
  def item
    render json: ITEM
  end
  
  # POST /api/payment/complete
  def complete
    payment_id = params[:paymentId]
    
    unless payment_id.is_a?(String)
      return render plain: '올바르지 않은 요청입니다.', status: 400
    end
    
    payment = sync_payment(payment_id)
    
    unless payment
      return render plain: '결제 동기화에 실패했습니다.', status: 400
    end
    
    render json: { status: payment[:status] }
  rescue => e
    render plain: e.message, status: 500
  end
  
  # POST /api/payment/webhook  
  def webhook
    # Webhook verification using raw body
    webhook_secret = Rails.application.credentials.dig(:portone, :webhook_secret)
    
    begin
      # Verify webhook signature
      webhook_data = verify_webhook(request.raw_post, request.headers, webhook_secret)
      
      # Process Transaction webhooks
      if webhook_data['type'] == 'Transaction.Paid' || 
         webhook_data['type'] == 'Transaction.VirtualAccountIssued'
        payment_id = webhook_data.dig('data', 'paymentId')
        sync_payment(payment_id) if payment_id
      end
      
      head :ok
    rescue PortOneWebhook::WebhookVerificationError => e
      Rails.logger.error "Webhook verification failed: #{e.message}"
      head :bad_request
    rescue PortOneWebhook::InvalidInputError => e
      Rails.logger.error "Webhook invalid input: #{e.message}"
      head :bad_request
    rescue => e
      Rails.logger.error "Webhook error: #{e.message}"
      head :bad_request
    end
  end
  
  private
  
  def sync_payment(payment_id)
    # Initialize payment if not exists
    @@payment_store[payment_id] ||= { status: 'PENDING' }
    payment = @@payment_store[payment_id]
    
    # Get payment from PortOne API
    api_secret = Rails.application.credentials.dig(:portone, :api_secret)
    actual_payment = fetch_payment_from_portone(payment_id, api_secret)
    
    return false unless actual_payment
    
    case actual_payment['status']
    when 'PAID'
      return false unless verify_payment(actual_payment)
      return payment if payment[:status] == 'PAID'
      
      payment[:status] = 'PAID'
      Rails.logger.info "결제 성공: #{actual_payment}"
    when 'VIRTUAL_ACCOUNT_ISSUED'
      payment[:status] = 'VIRTUAL_ACCOUNT_ISSUED'
    else
      return false
    end
    
    payment
  end
  
  def verify_payment(payment)
    # Skip channel type check for testing (like Express sample)
    # return false if payment['channel']['type'] != 'LIVE'
    
    return false unless payment['customData']
    
    custom_data = JSON.parse(payment['customData'])
    item_id = custom_data['item']
    
    return false unless item_id == ITEM[:id]
    
    payment['orderName'] == ITEM[:name] &&
      payment['amount']['total'] == ITEM[:price] &&
      payment['currency'] == ITEM[:currency]
  end
  
  def fetch_payment_from_portone(payment_id, api_secret)
    conn = Faraday.new(url: 'https://api.portone.io') do |f|
      f.request :json
      f.response :json
      f.headers['Authorization'] = "PortOne #{api_secret}"
    end
    
    response = conn.get("/payments/#{payment_id}")
    
    return nil unless response.success?
    response.body
  rescue => e
    Rails.logger.error "PortOne API error: #{e.message}"
    nil
  end
  
  def verify_webhook(body, headers, secret)
    PortOneWebhook.verify(secret, body, headers)
  end
end
