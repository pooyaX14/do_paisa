class StripeProcessor < Processor
  def process(options)
    charge_params = {
      amount: options[:amount],
      currency: currency
    }

    donor = Donor.find_by(id: options[:token])
    donor = add_donor(options[:token], options[:metadata]) if donor.nil?

    charge_params[:customer] = donor.external_id

    charge = Stripe::Charge.create(
      charge_params,
      api_key: api_secret
    )

    transaction = Transaction.create!(
      processor_id: id,
      amount: charge.amount,
      external_id: charge.id,
      status: charge.status,
      data: charge.to_json
    )

    {
      transaction_id: transaction.id,
      status: transaction.status,
      amount: transaction.amount,
      donor_id: donor.id
    }
  end

  def add_donor(token, metadata)
    customer = Stripe::Customer.create(
      {
        source: token
      },
      api_key: api_secret
    )

    donor = Donor.create!(
      processor_id: id,
      external_id: customer.id,
      data: customer.to_json,
      metadata: metadata
    )

    donor
  end
end
