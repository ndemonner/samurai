require 'spec_helper'

describe Samurai::Service do
  let!(:fake_service) do
    anonymous_class(Samurai::Service) do
      resource :users, expose: [:index, :create, :show]
      resource :companies, expose: [:show], with: 'CustomNamedController'
    end
  end

  it 'creates the proper routes and default controller name' do
    expect(fake_service.routes).to have_key(:users)
    expect(fake_service.routes[:users][:exposed]).to include(:index, :create, :show)
    expect(fake_service.routes[:users][:controller]).to eq('UsersController')
  end

  it 'uses a custom named controller if provided' do
    expect(fake_service.routes[:companies][:controller]).to eq('CustomNamedController')
  end

  it 'can be configured with a block' do
    mq = {hostname: 'mq.example.com', port: 1337}

    fake_service.configure do |c|
      c.message_queue = mq
    end

    expect(fake_service.configuration.message_queue).to eq(mq)
  end
end
