# frozen_string_literal: true

RSpec.describe Herb::Config do
  it "has a version number" do
    expect(Herb::Config::VERSION).not_to be_nil
  end
end
