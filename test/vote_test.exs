defmodule VoteTest do
  use ExUnit.Case
  doctest Vote

  test "something" do

    ballots = Enum.concat([
    	Enum.map(1..16, fn _ -> %{"a" => 1, "b" => 2, "c" => 3, "d" => 4} end),
    	Enum.map(1..24, fn _ -> %{"a" => 1, "b" => 3, "c" => 2, "d" => 4} end),
    	Enum.map(1..17, fn _ -> %{"a" => 2, "b" => 3, "c" => 4, "d" => 1} end)
    ])

    result = Vote.evaluate(ballots, 2)
    IO.inspect(result)
  end
end
