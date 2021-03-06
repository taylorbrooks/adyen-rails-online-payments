require 'json'

class CheckoutsController < ApplicationController
  def index
  end

  def preview
    @type = params[:type]
  end

  def get_payment_methods
     @type = params[:type]
    # The call to /paymentMethods will be made as the checkout page is requested.
    # The response will be passed to the front end via an instance variable,
    # which will be used to configure the instance of `AdyenCheckout`
    payment_methods_response = Checkout.get_payment_methods(@type).response.to_json

    @resp = payment_methods_response
    @client_key = ENV["CLIENT_KEY"]

    # The payment template (payment_template.html.erb) will be rendered with the
    # appropriate integration type (based on the params supplied).
    render 'payment_template'
  end

  def initiate_payment
    # The call to /payments will be made as the shopper selects the pay button.
    payment_response = Checkout.make_payment(params["paymentMethod"], params["riskData"].to_json, params["browserInfo"].to_json).response

    result_code = payment_response["resultCode"]
    action = payment_response["action"]
    paymentMethodType = params["paymentMethod"]["type"]

    session[:payment_data] = payment_response["paymentData"]
    
    render json: { action: action, resultCode: result_code, paymentMethodType: paymentMethodType }
  end

  def handle_shopper_redirect
    payload = {}
    payload["details"] = params
    payload["paymentData"] = session[:payment_data]

    resp = Checkout.submit_details(payload).response

    session[:payment_data] = ""

    case resp["resultCode"]
      when "Authorised"
        redirect_to '/success'
      when "Pending"
        redirect_to '/pending'
      when "Refused"
        redirect_to '/failed'
      else
        redirect_to '/error'
    end
  end

  def submit_additional_details
    payload = {}
    payload["details"] = params["details"]
    payload["paymentData"] = params["paymentData"]

    resp = Checkout.submit_details(payload).response

    action = resp["action"]
    resultCode = resp["resultCode"]

    render json: { action: action, resultCode: result_code }
  end

  def error
  end

  def failed
  end

  def pending
  end

  def success
  end
end
