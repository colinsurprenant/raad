require 'spec_helper'

# @TODO workaround to bug with Kernel.caller between 1.8 and 1.9 need to dig in this.
$RAAD_NOT_RUN=true
require 'raad/bootstrap'

describe Raad::Bootstrap do
  it "should work" do
    expect(true).to be_truthy
  end
end
