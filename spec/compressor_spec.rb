require 'helper'
require 'stringio'

describe Http2::Parser do

  context "compressor literal representation" do
    let(:c) { Compressor.new }
    let(:d) { Decompressor.new }

    context "integer" do
      it "should encode 10 using a 5-bit prefix" do
        buf = c.integer(10, 5)
        buf.should eq [10].pack('C')
        d.integer(StringIO.new(buf), 5).should eq 10
      end

      it "should encode 10 using a 0-bit prefix" do
        buf = c.integer(10, 0)
        buf.should eq [10].pack('C')
        d.integer(StringIO.new(buf), 0).should eq 10
      end

      it "should encode 1337 using a 5-bit prefix" do
        buf = c.integer(1337, 5)
        buf.should eq [31,128+26,10].pack('C*')
        d.integer(StringIO.new(buf), 5).should eq 1337
      end

      it "should encode 1337 using a 0-bit prefix" do
        buf = c.integer(1337,0)
        buf.should eq [128+57,10].pack('C*')
        d.integer(StringIO.new(buf), 0).should eq 1337
      end
    end

    context "string" do
      it "should handle ascii codepoints" do
        ascii = "abcdefghij"
        len, str = c.string(ascii)

        len.should eq c.integer(ascii.bytesize,0)
        str.should eq ascii

        buf = StringIO.new(len+str+"trailer")
        d.string(buf).should eq ascii
      end

      it "should handle utf-8 codepoints" do
        utf8 = "éáűőúöüó€"
        len, str = c.string(utf8)

        len.should eq c.integer(utf8.bytesize,0)
        str.should eq utf8

        buf = StringIO.new(len+str+"trailer")
        d.string(buf).should eq utf8
      end

      it "should handle long utf-8 strings" do
        utf8 = "éáűőúöüó€"*100
        len, str = c.string(utf8)

        len.should eq c.integer(utf8.bytesize,0)
        str.should eq utf8

        buf = StringIO.new(len+str+"trailer")
        d.string(buf).should eq utf8
      end
    end

  end
end
