#!/usr/bin/env ruby

# take lines from stdin, and obtain the first and last numeral on each line
# combine these into a two-digit number
# sum these numbers

$numerals = %w(zero one two three four five six seven eight nine)

# rnn is "replace numeral names"
# this function extracts the numerals from a string, whether the numeral
# is spelt out in English or as a Hindu-Arabic numeral
#
# call with acc initially set to empty list
def rnn(acc, s)
  if s == "" then return acc end

  for i in 0..9
    if s.start_with?($numerals[i]) then
      s[0] = (48 + i).chr
      break
    end
  end

  if s[0] >= '0' and s[0] <= '9' then
    return rnn(acc + [s[0]], s[1..])
  else
    return rnn(acc, s[1..])
  end
end

# Get all the digits in string 's' as a list
def digits(s)
  rnn([], s).map do |c| c.ord - 48 end
end

tally = 0

STDIN.each do |line|
  dd = digits(line)
  first = dd[0]
  last = dd[-1]
  tmp = first * 10 + last # should throw an exception if insufficient digits
  puts tmp
  tally += tmp
end

puts tally
