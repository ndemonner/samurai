require 'spec_helper'

describe 'Samurai::Service integration' do
  before(:each) do
    fake_controller_class = anonymous_class(Samurai::Controller) do
      def index
        [:ok, [1, 2, 3]]
      end

      def create(data)
        [:ok, data]
      end
    end

    @fake_service = anonymous_class(Samurai::Service) do
      resource :users, expose: [:index, :create, :show], with: fake_controller_class
    end
  end

  it 'rejects unhandled resources' do
    req = {'type' => 'request', 'resource' => 'companies', 'action' => 'index'}
    expect(@fake_service.handle(req)).to eq([:not_found, "Resource '#{req[:resource].to_s}' is not handled by this service"])
  end

  it 'rejects unexposed actions' do
    req = {'type' => 'request', 'resource' => 'users', 'action' => 'destroy'}
    expect(@fake_service.handle(req)).to eq([:not_found, "Action ##{req[:action].to_s} is not exposed by this service"])
  end

  it "returns an error if the controller doesn't define an exposed action method" do
    req = {'type' => 'request', 'resource' => 'users', 'action' => 'show'}
    expected_value = [:not_found, "Exposed action ##{req[:action].to_s} not defined on the controller"]
    expect(@fake_service.handle(req)).to eq(expected_value)
  end

  it "returns correctly for actions without params" do
    req = {'type' => 'request', 'resource' => 'users', 'action' => 'index'}

    expected_value = [:ok, [1, 2, 3]]
    expect(@fake_service.handle(req)).to eq(expected_value)
  end

  it "returns correctly for actions without params" do
    data = {'some' => 'cool', 'info' => 'here'}
    req = {'type' => 'request', 'resource' => 'users', 'action' => 'create', 'data' => data}

    expected_value = [:ok, data]
    expect(@fake_service.handle(req)).to eq(expected_value)
  end
end
