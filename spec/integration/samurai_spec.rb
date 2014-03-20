require 'spec_helper'

describe Samurai do
  let! :user_class do
    anonymous_class(Samurai::Proxy) do
      attr_accessor :id, :name, :email

      provides :users
    end
  end

  let! :service_class do
    controller_class = anonymous_class(Samurai::Controller) do
      def index
        [:ok, users(4)]
      end

      def create
        [:ok, users[0].merge(params)]
      end

      def show
        [:ok, {id: params[:id], name: "Bob ##{params[:id]}", email: "bob_#{params[:id]}@example.com"}]
      end

      private
      # helper method which pretends to grab some stuff from a db
      def users(amount = 1)
        amount.times.map do |n|
          {id: n + 1, name: "Bob ##{n + 1}", email: "bob_#{n + 1}@example.com"}
        end
      end
    end

    anonymous_class(Samurai::Service) do
      resource :users, expose: [:index, :create, :show, :update], with: controller_class

      configure do |c|
        c.log_level = :debug
        c.clear_log_on_load = true
        c.log_to_console = false
      end
    end
  end

  before(:each) { service_class.start! }
  after(:each)  { service_class.stop! }

  it 'fetches all of the objects for a resource' do
    expect(user_class.all).to have(4).items
  end

  it 'can fetch one specific user' do
    expect(user_class.find(1).id).to eq(1)
  end
end
