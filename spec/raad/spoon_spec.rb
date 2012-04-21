require 'spec_helper'
require 'raad//env'
require 'raad/spoon' if Raad.jruby?

if Raad.jruby?

  describe Spoon do
    it "should work" do
      true.should be_true
    end
  end

end