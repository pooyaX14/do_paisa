describe NotificationMailer do
  before do 
    @email_template = FactoryBot.create(:one_off_success_email_template)
    @stripe_processor = FactoryBot.create(:stripe_processor_with_donor)
    @email_template.update_attributes(
      processor: @stripe_processor,
      subject: 'Thanks {{first_name}}'
      )

    @stripe_processor.donors.first.update_attributes(metadata: {
      first_name: "Jason",
      last_name: "Bourne",
      email: 'test@example.com'
      })
  end

  it "sends an email" do 
    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).one_off_success.deliver_now
    email = ActionMailer::Base.deliveries.last
 
    expect(email.subject).to eq "Thanks Jason" 
    expect(email.to[0]).to eq 'test@example.com' 
  end

  it "doesn't send an email if the template is not defined" do 
    @email_template.destroy

    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).one_off_success.deliver_now
    expect(ActionMailer::Base.deliveries.count).to eq 0
  end

  it "correctly merges tags into the subject line" do 
    @email_template.update_attributes(subject: 'Thanks {{first_name}} {{last_name}}, donation of {{amount}}')
    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).one_off_success.deliver_now

    email = ActionMailer::Base.deliveries.last
    amount_in_cents = @stripe_processor.donors.first.transactions.first.amount
    amount_string = '$' + "%.2f" % (amount_in_cents.to_f / 100)
 
    expect(email.subject).to eq "Thanks Jason Bourne, donation of #{amount_string}" 
    expect(email.to[0]).to eq 'test@example.com'
  end

  it "correctly merges tags into the body" do 
    @email_template.update_attributes(html: 'Dear {{first_name}}<br /><br />Thanks for your generous donation of {{amount}}!')
    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).one_off_success.deliver_now

    email = ActionMailer::Base.deliveries.last
    amount_in_cents = @stripe_processor.donors.first.transactions.first.amount
    amount_string = '$' + "%.2f" % (amount_in_cents.to_f / 100)

    expect(email.body.raw_source).to eq "Dear Jason<br /><br />Thanks for your generous donation of #{amount_string}!" 
    expect(email.to[0]).to eq 'test@example.com'    
  end

  it "sets the sender name and email correctly" do 
    @email_template.update_attributes(sender_name: "Mr Blobby", sender_email: 'mr@blobby.com')
    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).one_off_success.deliver_now
    email = ActionMailer::Base.deliveries.last

    expect(email.From.value).to eq "Mr Blobby <mr@blobby.com>"
  end

  it "sends correct email for one_off_success" do 
    template2 = @email_template.dup
    template2.email_type = :recurring_start
    template2.subject = "Wrong"
    @email_template.processor.processor_email_templates << template2
    
    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).one_off_success.deliver_now
    email = ActionMailer::Base.deliveries.last
 
    expect(email.subject).to eq "Thanks Jason" 
  end

  it "sends correct email for recurring_started" do 
    template2 = @email_template.dup
    template2.email_type = :recurring_fail
    template2.subject = "Wrong"
    @email_template.processor.processor_email_templates << template2
    @email_template.update_attributes(email_type: :recurring_start)
    
    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).recurring_started.deliver_now
    email = ActionMailer::Base.deliveries.last
 
    expect(email.subject).to eq "Thanks Jason" 
  end

  it "sends correct email for recurring_fail" do 
    template2 = @email_template.dup
    template2.email_type = :recurring_start
    template2.subject = "Wrong"
    @email_template.processor.processor_email_templates << template2
    @email_template.update_attributes(email_type: :recurring_fail)

    NotificationMailer.with(transaction: @stripe_processor.donors.first.transactions.first).recurring_fail.deliver_now
    email = ActionMailer::Base.deliveries.last
 
    expect(email.subject).to eq "Thanks Jason" 
  end

  it "saves a DonorEmail instance with all the details" do 

  end
end