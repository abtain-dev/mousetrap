require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mousetrap::Customer do
  # customers: 
  #   customer: 
  #     firstName: nvnawrelyv
  #     lastName: vklidifvfd
  #     email: bvvljaeegs@example.com
  #     code: ablntsorai@example.com
  #     company: 
  #     gatewayToken: 
  #     id: eac1cf0e-fc5b-102c-a92d-40402145ee8b
  #     createdDatetime: "2009-09-27T02:16:15+00:00"
  #     modifiedDatetime: "2009-09-27T02:16:16+00:00"
  #     subscriptions: 
  #       subscription: 
  #         gatewayToken: 
  #         id: eac26b4e-fc5b-102c-a92d-40402145ee8b
  #         createdDatetime: "2009-09-27T02:16:15+00:00"
  #         ccType: visa
  #         ccLastFour: "1111"
  #         ccExpirationDate: "2012-12-31T00:00:00+00:00"
  #         canceledDatetime: 
  #         plans: 
  #           plan: 
  #             name: Test
  #             setupChargeAmount: "0.00"
  #             code: TEST
  #             recurringChargeAmount: "42.00"
  #             billingFrequencyQuantity: "1"
  #             trialDays: "0"
  #             id: 5fbb9a84-e27f-102c-a92d-40402145ee8b
  #             billingFrequency: monthly
  #             createdDatetime: "2009-08-25T04:24:34+00:00"
  #             recurringChargeCode: TEST_RECURRING
  #             isActive: "1"
  #             billingFrequencyUnit: months
  #             description: Test
  #             billingFrequencyPer: month
  #             setupChargeCode: TEST_SETUP
  #         invoices: 
  #           invoice: 
  #             number: "2"
  #             billingDatetime: "2009-10-27T02:16:15+00:00"
  #             id: eac74d62-fc5b-102c-a92d-40402145ee8b
  #             createdDatetime: "2009-09-27T02:16:15+00:00"
  #             type: subscription
  
  def customer_attributes_for_api(customer)
    {
      :firstName => customer.first_name,
      :lastName => customer.last_name,
      :email => customer.email,
      :code => customer.code,
      :subscription => {
        :planCode     => customer.subscription.plan_code,
        :ccFirstName  => customer.subscription.billing_first_name,
        :ccLastName   => customer.subscription.billing_last_name,
        :ccNumber     => customer.subscription.credit_card_number,
        :ccExpMonth   => customer.subscription.credit_card_expiration_month,
        :ccExpYear    => customer.subscription.credit_card_expiration_year,
        :ccZip        => customer.subscription.billing_zip_code,
      }
    }
  end

  describe '.all' do
    before do
      Mousetrap::Customer.stub :build_resources_from
    end

    it "gets all customers" do
      Mousetrap::Customer.should_receive(:get_resources).with('customers').and_return('some hash')
      Mousetrap::Customer.all
    end

    it "handles kludgy 'no customers found' response" do
      Mousetrap::Customer.stub :get_resources => { 'error' => "Bad request: No customers found." }
      Mousetrap::Customer.all.should == []
    end

    it "raises error if response has one" do
      expect do
        Mousetrap::Customer.stub :get_resources => { 'error' => "some other error" }
        Mousetrap::Customer.all
      end.to raise_error(RuntimeError, "some other error")
    end

    it "builds resources from the response" do
      Mousetrap::Customer.stub :get_resources => 'some hash'
      Mousetrap::Customer.should_receive(:build_resources_from).with('some hash')
      Mousetrap::Customer.all
    end
  end

  describe '.create' do
    before do
      @customer_hash = Factory.attributes_for :new_customer
      @customer = Mousetrap::Customer.new @customer_hash
      @customer.stub(:save)
      Mousetrap::Customer.stub(:new => @customer)
      Mousetrap::Customer.stub(:build_resource_from => stub(:id => 0))
    end

    it 'instantiates a customer with a hash of attributes' do
      Mousetrap::Customer.should_receive(:new).with(@customer_hash).and_return(@customer)
      Mousetrap::Customer.create(@customer_hash)
    end

    it 'saves the new customer instance' do
      @customer.should_receive(:save)
      Mousetrap::Customer.create(@customer_hash)
    end

    it 'sets the id of the newly created customer' do
      Mousetrap::Customer.stub(:build_resource_from => stub(:id => 1))
      @customer.should_receive(:id=).with(1)
      Mousetrap::Customer.create(@customer_hash)
    end

    it 'returns an instance of Mousetrap::Customer' do
      Mousetrap::Customer.create(@customer_hash).should be_instance_of(Mousetrap::Customer)
    end
  end

  describe ".new" do
    subject do
      Mousetrap::Customer.new \
        :first_name => 'Jon',
        :last_name => 'Larkowski',
        :email => 'lark@example.com',
        :code => 'asfkhw0'
    end

    it { should be_instance_of(Mousetrap::Customer) }
    it { should be_new_record }

    describe "sets" do
      it 'first_name' do
        subject.first_name.should == 'Jon'
      end

      it 'last_name' do
        subject.last_name.should == 'Larkowski'
      end

      it 'email' do
        subject.email.should == 'lark@example.com'
      end

      it 'code' do
        subject.code.should == 'asfkhw0'
      end
    end
  end

  describe '#cancel' do
    context "for existing records" do
      it 'cancels' do
        customer = Factory :existing_customer
        customer.should_receive(:member_action).with('cancel')
        customer.cancel
      end
    end

    context "for new records" do
      it "does nothing" do
        customer = Factory.build :new_customer
        customer.should_not_receive(:member_action).with('cancel')
        customer.cancel
      end
    end
  end

  describe '#save' do
    context "for existing records" do
      before do
        @customer = Factory :existing_customer
      end

      it 'posts to edit-customer action' do
        attributes_for_api = customer_attributes_for_api(@customer)

        # We don't send code for existing API resources.
        attributes_for_api.delete(:code)

        @customer.class.should_receive(:put_resource).with(
          'customers', 'edit-customer', @customer.code, attributes_for_api)
        @customer.save
      end
    end

    context "for new records" do
      it 'calls create' do
        customer = Factory :new_customer
        customer.should_receive(:create)
        customer.save
      end
    end
  end
end
