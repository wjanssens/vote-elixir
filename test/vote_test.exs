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

    c = Map.get(result, "a")
    assert c.round == 1
    assert c.votes == 40
    assert c.surplus == 20
    assert c.status == :elected

    c = Map.get(result, "b")
    assert c.round == 2
    assert c.votes == 8
    assert c.status == :excluded

    c = Map.get(result, "c")
    assert c.round == 3
    assert c.votes == 20
    assert c.surplus == 0
    assert c.status == :elected

    c = Map.get(result, "d")
    assert c.votes == 17
  end


  test "animal_stv_1" do

    ballots = Enum.concat([
      Enum.map(1..05, fn _ -> %{"tarsier" => 1, "gorilla" => 2} end),
      Enum.map(1..28, fn _ -> %{"gorilla" => 1} end),
      Enum.map(1..33, fn _ -> %{"monkey" => 1} end),
      Enum.map(1..21, fn _ -> %{"tiger" => 1} end),
      Enum.map(1..13, fn _ -> %{"lynx" => 1, "tiger" => 2} end)
    ])

    result = Vote.stv(ballots, 3)

    # these results differ from CGP grey since he used Hare quota and this is using Droop quota
    c = Map.get(result, "monkey")
    assert c.round == 1
    assert c.votes == 33
    assert c.surplus == 7
    assert c.status == :elected

    c = Map.get(result, "gorilla")
    assert c.round == 2
    assert c.votes == 28
    assert c.surplus == 2
    assert c.status == :elected

    c = Map.get(result, "tarsier")
    assert c.round == 3
    assert c.votes == 5
    assert c.status == :excluded

    c = Map.get(result, "lynx")
    assert c.round == 4
    assert c.votes == 13
    assert c.status == :excluded

    c = Map.get(result, "tiger")
    assert c.round == 5
    assert c.votes == 34
    assert c.status == :elected
  end

  test "animal_stv_2" do

    ballots = Enum.concat([
      Enum.map(1..65, fn _ -> %{"white tiger" => 1, "tiger" => 2} end),
      Enum.map(1..01, fn _ -> %{"tiger" => 1, "white tiger" => 2} end),
      Enum.map(1..16, fn _ -> %{"silverback" => 1, "gorilla" => 2} end),
      Enum.map(1..18, fn _ -> %{"gorilla" => 1, "silverback" => 2} end),
    ])

    result = Vote.stv(ballots, 3)

    # these results differ from CGP grey since he used Hare quota and this is using Droop quota
    c = Map.get(result, "white tiger")
    assert c.round == 1
    assert c.votes == 65
    assert c.surplus == 39
    assert c.status == :elected
    assert c.exhausted == 0

    c = Map.get(result, "tiger")
    assert c.round == 2
    assert c.votes == 40
    assert c.surplus == 14
    assert c.status == :elected
    assert c.exhausted == 14

    c = Map.get(result, "silverback")
    assert c.round == 3
    assert c.votes == 16
    assert c.status == :excluded
    assert c.exhausted == 0

    c = Map.get(result, "gorilla")
    assert c.round == 4
    assert c.votes == 34
    assert c.status == :elected
    assert c.exhausted == 8
  end

  test "animal_stv_3" do
    ballots = Enum.concat([
      Enum.map(1..05, fn _ -> %{"tarsier" => 1, "silverback" => 2} end),
      Enum.map(1..10, fn _ -> %{"gorilla" => 1, "tarsier" => 2, "silverback" => 3} end),
      Enum.map(1..22, fn _ -> %{"gorilla" => 1, "silverback" => 2} end),
      Enum.map(1..03, fn _ -> %{"silverback" => 1} end),
      Enum.map(1..33, fn _ -> %{"owl" => 1, "turtle" => 2} end),
      Enum.map(1..01, fn _ -> %{"turtle" => 1} end),
      Enum.map(1..01, fn _ -> %{"snake" => 1, "turtle" => 2} end),
      Enum.map(1..16, fn _ -> %{"tiger" => 1} end),
      Enum.map(1..04, fn _ -> %{"lynx" => 1, "tiger" => 2} end),
      Enum.map(1..02, fn _ -> %{"jackalope" => 1} end),
      Enum.map(1..02, fn _ -> %{"buffalo" => 1, "jackalope" => 2} end),
      Enum.map(1..01, fn _ -> %{"buffalo" => 1, "jackalope" => 2, "turtle" => 3} end),
    ])

    result = Vote.stv(ballots, 5)

    # these results differ from CGP grey since he used Hare quota (20) and this is using Droop (17) quota
    c = Map.get(result, "owl")
    assert c.round == 1
    assert c.votes == 33
    assert c.surplus == 16
    assert c.status == :elected
    assert c.exhausted == 0

    c = Map.get(result, "gorilla")
    assert c.round == 2
    assert c.votes == 32
    assert c.surplus == 15
    assert c.status == :elected
    assert c.exhausted == 0

    c = Map.get(result, "turtle")
    assert c.round == 3
    assert c.votes == 17
    assert c.surplus == 0
    assert c.status == :elected
    assert c.exhausted == 0

    c = Map.get(result, "snake")
    assert c.round == 4
    assert c.votes == 1
    assert c.status == :excluded
    assert c.exhausted == 1

    c = Map.get(result, "jackalope")
    assert c.round == 5
    assert c.votes == 2
    assert c.status == :excluded
    assert c.exhausted == 2

    c = Map.get(result, "buffalo")
    assert c.round == 6
    assert c.votes == 3
    assert c.status == :excluded
    assert c.exhausted == 3

    c = Map.get(result, "lynx")
    assert c.round == 7
    assert c.votes == 4
    assert c.status == :excluded
    assert c.exhausted == 0

    c = Map.get(result, "tiger")
    assert c.round == 8
    assert c.votes == 20
    assert c.status == :elected
    assert c.surplus == 3
    assert c.exhausted == 3

    c = Map.get(result, "tarsier")
    assert c.round == 9
    assert c.votes == 9.6875
    assert c.status == :excluded
    assert c.exhausted == 0

    c = Map.get(result, "silverback")
    assert c.round == 10
    assert c.votes == 23
    assert c.status == :elected
    assert c.exhausted == 6
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

    c = Map.get(result, "a")
    assert c.votes == 16

    c = Map.get(result, "b")
    assert c.votes == 24
    assert c.status == :elected

    c = Map.get(result, "c")
    assert c.votes == 11

    c = Map.get(result, "d")
    assert c.votes == 17
  end

  test "approval" do
    ballots = Enum.concat([
      Enum.map(1..16, fn _ -> %{"a" => 1, "b" => 1} end),
      Enum.map(1..24, fn _ -> %{"a" => 1, "c" => 1} end),
      Enum.map(1..17, fn _ -> %{"a" => 1, "d" => 1} end)
    ])

    result = Vote.approval(ballots, 2)
    # IO.inspect result

    c = Map.get(result, "a")
    assert c.votes == 57
    assert c.status == :elected

    c = Map.get(result, "b")
    assert c.votes == 16

    c = Map.get(result, "c")
    assert c.votes == 24
    assert c.status == :elected

    c = Map.get(result, "d")
    assert c.votes == 17
  end
end
