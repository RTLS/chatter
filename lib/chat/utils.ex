defmodule Chat.Utils do
  def format_datetime(%DateTime{} = datetime) do
    cond do
      # is it today?
      DateTime.to_date(datetime) === Date.utc_today() ->
        format_as_time(datetime)

      # is it in the last week?
      Date.diff(DateTime.to_date(datetime), Date.utc_today()) > -6 ->
        format_as_day_of_week(datetime)

      # older than a week
      true ->
        format_as_date(datetime)
    end
  end

  defp format_as_time(%DateTime{hour: hour, minute: minute}) do
    minute = minute |> to_string() |> String.pad_leading(2, "0")
    "#{hour}:#{minute}"
  end

  defp format_as_day_of_week(%DateTime{} = datetime) do
    time = format_as_time(datetime)

    case datetime |> DateTime.to_date() |> Date.day_of_week() do
      1 -> "Mon " <> time
      2 -> "Tue " <> time
      3 -> "Wed " <> time
      4 -> "Thur " <> time
      5 -> "Fri " <> time
      6 -> "Sat " <> time
      7 -> "Sun " <> time
    end
  end

  defp format_as_date(%DateTime{year: year, month: month, day: day}),
    do: "#{month}/#{day}/#{year}"
end
