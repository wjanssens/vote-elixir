defmodule VoteTest do
  use ExUnit.Case
  doctest Vote

  test "stv" do

    ballots = Enum.concat([
    	Enum.map(1..16, fn _ -> %{"a" => 1, "b" => 2, "c" => 3, "d" => 4} end),
    	Enum.map(1..24, fn _ -> %{"a" => 1, "b" => 3, "c" => 2, "d" => 4} end),
    	Enum.map(1..17, fn _ -> %{"a" => 2, "b" => 3, "c" => 4, "d" => 1} end)
    ])

    result = Vote.stv(ballots, 2)
    # IO.inspect result

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


  test "animal_stv_1" do

    ballots = Enum.concat([
      Enum.map(1..05, fn _ -> %{"tarsier" => 1, "gorilla" => 2} end),
      Enum.map(1..28, fn _ -> %{"gorilla" => 1} end),
      Enum.map(1..33, fn _ -> %{"monkey" => 1} end),
      Enum.map(1..21, fn _ -> %{"tiger" => 1} end),
      Enum.map(1..13, fn _ -> %{"lynx" => 1, "tiger" => 2} end)
    ])

    fptp = Vote.plurality(ballots)
    assert Map.get(fptp, "monkey").status == :elected

    result = Vote.stv(ballots, 3)

    # these results differ from CGP grey since he used Hare quota and this is using Droop quota
    monkey = Map.get(result, "monkey")
    assert monkey.round == 1
    assert monkey.votes == 33
    assert monkey.surplus == 7
    assert monkey.status == :elected

    gorilla = Map.get(result, "gorilla")
    assert gorilla.round == 2
    assert gorilla.votes == 28
    assert gorilla.surplus == 2
    assert gorilla.status == :elected

    tarsier = Map.get(result, "tarsier")
    assert tarsier.round == 3
    assert tarsier.votes == 5
    assert tarsier.status == :excluded

    lynx = Map.get(result, "lynx")
    assert lynx.round == 4
    assert lynx.votes == 13
    assert lynx.status == :excluded

    lynx = Map.get(result, "tiger")
    assert lynx.round == 5
    assert lynx.votes == 34
    assert lynx.status == :elected
  end

  test "animal_stv_2" do

    ballots = Enum.concat([
      Enum.map(1..65, fn _ -> %{"white tiger" => 1, "tiger" => 2} end),
      Enum.map(1..01, fn _ -> %{"tiger" => 1, "white tiger" => 2} end),
      Enum.map(1..16, fn _ -> %{"silverback" => 1, "gorilla" => 2} end),
      Enum.map(1..18, fn _ -> %{"gorilla" => 1, "silverback" => 2} end),
    ])

    fptp = Vote.plurality(ballots)
    assert Map.get(fptp, "white tiger").status == :elected

    result = Vote.stv(ballots, 3)

    # these results differ from CGP grey since he used Hare quota and this is using Droop quota
    w = Map.get(result, "white tiger")
    assert w.round == 1
    assert w.votes == 65
    assert w.surplus == 39
    assert w.status == :elected

    t = Map.get(result, "tiger")
    assert t.round == 2
    assert t.votes == 40
    assert t.surplus == 14
    assert t.status == :elected

    s = Map.get(result, "silverback")
    assert s.round == 3
    assert s.votes == 16
    assert s.status == :excluded

    g = Map.get(result, "gorilla")
    assert g.round == 4
    assert g.votes == 34  
    assert g.status == :elected
  end


  test "plurality" do
    ballots = Enum.concat([
      Enum.map(1..16, fn _ -> %{"a" => 1} end),
      Enum.map(1..24, fn _ -> %{"b" => 1} end),
      Enum.map(1..11, fn _ -> %{"c" => 1} end),
      Enum.map(1..17, fn _ -> %{"d" => 1} end)
    ])

    result = Vote.plurality(ballots)
    # IO.inspect result

    a = Map.get(result, "a")
    assert a.votes == 16

    b = Map.get(result, "b")
    assert b.votes == 24
    assert b.status == :elected

    c = Map.get(result, "c")
    assert c.votes == 11

    d = Map.get(result, "d")
    assert d.votes == 17
  end

  test "approval" do
    ballots = Enum.concat([
      Enum.map(1..16, fn _ -> %{"a" => 1, "b" => 1} end),
      Enum.map(1..24, fn _ -> %{"a" => 1, "c" => 1} end),
      Enum.map(1..17, fn _ -> %{"a" => 1, "d" => 1} end)
    ])

    result = Vote.approval(ballots, 2)
    # IO.inspect result

    a = Map.get(result, "a")
    assert a.votes == 57
    assert a.status == :elected

    b = Map.get(result, "b")
    assert b.votes == 16

    c = Map.get(result, "c")
    assert c.votes == 24
    assert c.status == :elected

    d = Map.get(result, "d")
    assert d.votes == 17
  end
end
