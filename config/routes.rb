Rails.application.routes.draw do

  scope path: 'payments', module: 'payments' do
    get 'new' => 'paypal_express#new', as: :paypal_payment
    get 'cancel' => 'paypal_express#cancel', as: :paypal_cancel
    get 'purchase' => 'paypal_express#purchase', as: :paypal_purchase
    get 'complete' => 'paypal_express#complete', as: :paypal_complete
    get 'fail' => 'paypal_express#fail', as: :paypal_fail
    post 'notify'  => 'paypal_express#ipn', as: :paypal_ipn
  end
end
