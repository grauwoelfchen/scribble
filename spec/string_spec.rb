#!/usr/bin/env ruby
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'String' do
  context 'when string is empty' do
    before { @string = '' }
    describe 'String#rpad' do
      context 'with 0' do
        it 'should return empty string' do
          @string.rpad(0).should be_empty
        end
      end
      context 'with -3' do
        it 'should return empty string' do
          @string.rpad(-3).should be_empty
        end
      end
      context 'with 3' do
        it 'should return 3 whitespace with arg 3' do
          @string.rpad(3).should eq '   '
        end
      end
      context 'with non-numeric arg' do
        it 'should raise ArgumentError' do
          proc { @string.rpad('bad') }.should raise_error ArgumentError
        end
      end
    end
    describe 'String#rtrim' do
      context 'with non-numeric arg' do
        it 'should raise TypeError' do
          proc { @string.rtrim('bad') }.should raise_error TypeError
        end
      end
      context 'with -3' do
        it 'should return empty string' do
          @string.rtrim(-3).should eq ''
        end
      end
      context 'with 3' do
        it 'should return empty string' do
          @string.rtrim(3).should eq ''
        end
      end
    end
    describe "String#width" do
      it 'return 0' do
        expect { subject.width }.eql? 0
      end
    end
  end
  context 'when string is "Dankeschön"' do
    before { subject = "Dankeschön" }
    describe 'String#rpad' do
      context 'with 2' do
        it 'should not be pad any space' do
          expect { subject.rpad(2) }.eql? "Dankeschön"
        end
      end
      context 'with 12' do
        it 'should be pad blank space' do
          expect { subject.rpad(12) }.eql? "Dankeschön  "
        end
      end
    end
  end
end
