require 'spec_helper'

describe Samurai::Proxy do
  let!(:fake_proxy) do
    anonymous_class(Samurai::Proxy) do
      provides :users
    end
  end
end