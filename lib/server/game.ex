defmodule Server.Game do
  defstruct [:tetro, points: [], score: 0, junkyard: %{}, game_over: false]
  alias Server.{Tetromino, Points}
  alias ServerWeb.Mylib.O
  # def new do
  #   __struct__()
  #   |> O.K.put_v(:tetro,Tetromino.new_random() )
  #   |> O.K.put(:points,&(Tetromino.show(&1.tetro)))
  # end
  def new_ticker(ticker) do
    __struct__()
    |> O.K.put_v(:tetro,Tetromino.new_random_ticker(ticker) )
    |> O.K.put(:points,&(Tetromino.show(&1.tetro)))
  end
  def junkyard_points(o) do
    o.junkyard
    |> Enum.map(fn {{x, y}, shape} -> {x, y, shape} end)
  end

  def move(game, move_fn) do
    {old, new, valid} = move_data(game, move_fn)
    moved = Tetromino.maybe_move(old, new, valid)

    %{game| tetro:  moved}
    |> O.K.put(:points,&(Tetromino.show(&1.tetro)))
  end

  defp move_data(game, move_fn) do
    old = game.tetro
    new =
      game.tetro
      |> move_fn.()
    valid =
      new
      |> Tetromino.show
      |> Points.valid?(game.junkyard)

    {old, new, valid}
  end

  def down(game,click_ticker) do
    ticker = case click_ticker do
       nil -> "aapl"
        _ -> click_ticker |> String.slice(9..100)
    end
    {old, new, valid} = move_data(game, &Tetromino.down/1)
    move_down_or_merge(game, old, new, valid,ticker)

  end

  def move_down_or_merge(game, _old, new, true=_valid,_click) do
    %{game| tetro: new}
    |> O.K.put(:points,&(Tetromino.show(&1.tetro)))
    |> inc_score(1)
  end

  def move_down_or_merge(game, old, _new, false=_valid,ticker) do
    game
    |> merge(old)
    |> Map.put(:tetro,Tetromino.new_random_ticker(ticker) )
    |> O.K.put(:points,&(Tetromino.show(&1.tetro)))
    |> check_game_over
  end

  def merge(game, old) do
    new_junkyard =
      old
      |> Tetromino.show
      |> Enum.map(fn {x, y, shape} -> {{x, y}, shape} end)
      |> Enum.into(game.junkyard)

    %{game| junkyard: new_junkyard}
    |> collapse_rows
  end

  def collapse_rows(game) do
    rows = complete_rows(game)

    game
    |> absorb(rows)
    |> score_rows(rows)
  end

  def absorb(game, []), do: game
  def absorb(game, [y|ys]), do: remove_row(game, y) |> absorb(ys)

  def remove_row(game, row) do
    new_junkyard =
      game.junkyard
      |> Enum.reject(fn {{_x, y}, _shape} -> y == row end )
      |> Enum.map(fn {{x, y}, shape} ->
        {{x, maybe_move_y(y, row)}, shape}
      end)
      |> Map.new
    %{game| junkyard: new_junkyard}
  end

  defp maybe_move_y(y, row) when y < row, do: y + 1
  defp maybe_move_y(y, _row), do: y

  def score_rows(game, rows) do
    new_score =
      :math.pow(2, length(rows))
      |> round
      |> Kernel.*(100)

    %{game|score: new_score}
  end

  defp complete_rows(game) do
    game.junkyard
    |> Map.keys
    |> Enum.group_by(&elem(&1, 1))
    |> Enum.filter(fn {_y, list} -> length(list) > 7 end)
    |> Enum.map(fn {y, _list} -> y end)
  end


  def left(game), do: game |> move(&Tetromino.left/1)
  def right(game), do: game |> move(&Tetromino.right/1)
  def rotate(game), do: game |> move(&Tetromino.rotate/1)
  def bottom(game), do: game |> move(&Tetromino.bottom/1)





  def inc_score(game, value) do
    %{game| score: game.score + value }
  end

  def check_game_over(game) do
    continue_game =
      game.tetro
      |> Tetromino.show
      |> Points.valid?(game.junkyard)

    %{game| game_over: !continue_game}
  end
end