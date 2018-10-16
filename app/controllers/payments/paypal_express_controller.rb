# 基本的な処理の流れは

# 1. new でPayPalの支払画面へ遷移
# 2. purchase で購入処理をして支払完了画面へ遷移
# 3. ipn でIPNを受け取って処理

module Payments
  class PaypalExpressController < ApplicationController
    # amount_in_cents
    AMOUNT_SAMPLE = 120 * 100

    def new
      response = gateway.setup_purchase(
        AMOUNT_SAMPLE,
        ip:           request.remote_ip,
        return_url:   paypal_purchase_url,
        cancel_return_url:  paypal_cancel_url,
        items: [
          {
            name: "a subject",
            quantity: 1,
            amount: AMOUNT_SAMPLE
          }])
      redirect_to gateway.redirect_url_for(response.token, review: false)
    end

    def purchase
      details = gateway.details_for(params[:token])

      purchase = gateway.purchase(
        AMOUNT_SAMPLE,
        ip:   request.remote_ip,
        token:  params[:token],
        payer_id: details.payer_id,
        notify_url: paypal_ipn_url)

      if purchase.success?
        redirect_to paypal_complete_path
      else
        logger.error 'purchase failed.'
        redirect_to paypal_fail_path
      end
    end

    def complete; render 'payments/complete'; end
    def cancel; render 'payments/cancel'; end
    def fail; render 'payments/fail'; end

    #  IPN を受け取ったときの処理
    def ipn
      response = OffsitePayments::Integrations::Paypal::Notification.new(request.new_post).extend(PaypalNotification)

      unless response.acknowledge
        logger.error 'invalid ipn'
        render nothing: true, status: :bad_request
      end

      if response.complete?(AMOUNT_SAMPLE)
        logger.info 'completed'
      elsif response.refunded?(AMOUNT_SAMPLE)
        logger.info 'refunded'
      else
        logger.error 'failed'
      end

      render nothing: true
    end

    private

    def gateway
      ActiveMerchant::Billing::PaypalExpressGateway.new(
        login: Rails.application.credentials.dig(:paypal, :login),
        password: Rails.application.credentials.dig(:paypal, :password),
        signature: Rails.application.credentials.dig(:paypal, :signature)
      )
    end
  end

  module PaypalNotification
    def completed?(amount)
      complete? && amount == gross.to_i
    end

    def refunded?(amount)
      status == 'Refunded' && (0 - amount) == gross.to_i
    end
  end
end
