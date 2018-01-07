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
    IO.inspect result

    a = Map.get(result, "a")
    assert a.round == 1
    assert a.votes == 40
    assert a.surplus == 20
    assert a.status == :elected

    b = Map.get(result, "b")
    assert b.round == 2
    assert b.votes == 8
    assert b.status == :excluded

    c = Map.get(result, "c")
    assert c.round == 3
    assert c.votes == 20
    assert c.surplus == 0
    assert c.status == :elected

    d = Map.get(result, "d")
    assert d.votes == 17
  end
end
