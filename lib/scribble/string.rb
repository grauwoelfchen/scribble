# encoding: utf-8

class String
  def width
    self.chars.map{ |c| c.bytesize >= 3 ? 2 : 1 }.reduce(0, &:+)
  end
  def rtrim trim_width
    if (self.width - trim_width) > 0
      count = 0
      chars = ''
      self.chars.each do |c|
        break if count >= trim_width
        chars << c
        count += c.bytesize >= 3 ? 2 : 1
      end
      chars
    else
      self
    end
  end
  def rpad pad_width
    return self if pad_width < 0
    self + (" " * pad_width)
  end
end
