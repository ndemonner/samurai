require 'spec_helper'

describe Samurai::Service do
  let!(:fake_controller_class) do
    anonymous_class(Samurai::Controller) do
      def index
        # Return some stuff
        [:ok, [1, 2, 3]]
      end

      def create(data)
        # Simple echo
        [:ok, data]
      end
    end
  end

  it "returns an error if the requested action doesn't exist" do
    method = :destroy
    expected_value = [:not_found, "Exposed action ##{method.to_s} not defined on the controller"]
    expect(fake_controller_class.new.try(method)).to eq(expected_value)
  end

  it 'calls actions without data' do
    expect(fake_controller_class.new.try(:index)).to eq([:ok, [1, 2, 3]])
  end

  it 'calls action with data' do
    data = {some: 'cool', info: 'here'}
    expect(fake_controller_class.new.try(:create, data)).to eq([:ok, data])
  end
end
