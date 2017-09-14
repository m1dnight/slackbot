defmodule Brain.DishwasherManager do
  require Logger
  use GenServer

  @users_file "data/dishwasher_manager/users.dat"
  @schedule_file "data/dishwasher_manager/schedule.dat"
  @holidays [~D[2017-12-25], ~D[2018-01-01] ]

  def start_link(initial_state \\ []) do
    GenServer.start_link __MODULE__, [initial_state], name: __MODULE__
  end

  def init([[]]) do
    Logger.debug "No orders provided. Reading from disk."
    case restore_state() do
      {:ok, state} ->
        {:ok, state}
      _ ->
        Logger.warn "No initial orders and can't read backup, starting with empty order."
        {:ok, {%{}, %{}, :no_specified}}
    end
  end

  def init([state]) do
    {:ok, state}

  end

  #############
  # Interface #
  #############

  def swap_duties(userA, userB) do
    GenServer.call __MODULE__, {:swap, userA, userB}
  end

  def manager?() do
    GenServer.call __MODULE__, :manager?
  end

  defp next_manager do
    GenServer.call __MODULE__, :next_manager
  end

  def when?(user) do
    GenServer.call __MODULE__, {:when?, user}
  end

  def schedule() do
    GenServer.call __MODULE__, :schedule
  end

  def create_schedule(startDate) do
    GenServer.call __MODULE__, {:create_schedule, startDate}
  end

  def users() do
    GenServer.call __MODULE__, :users
  end

  def add_user(user, fullname) do
    GenServer.call __MODULE__, {:add_user, user, fullname}
  end

  def remove_user(user) do
    GenServer.call __MODULE__, {:remove_user, user}
  end

  def set_manager_of_the_week() do
    GenServer.call __MODULE__, :set_manager_of_the_week
  end

  def remove_users() do
    GenServer.call __MODULE__, :remove_users
  end

  def remove_schedule() do
    GenServer.call __MODULE__, :remove_schedule
  end


  #########
  # Calls #
  #########

  def handle_call(:users, _from, {_, users, _} = state) do
    {:reply, {:ok, users}, state}
  end

  def handle_call(:manager?, _from, {_, users, manager} = state) do
    fullName = Keyword.get(users, manager, :no_specified)
    {:reply, {:ok, Atom.to_string(manager), fullName}, state}
  end

  def handle_call(:next_manager, _from, {schedule, users, _} = state) do
    manager =
      case get_next_manager(schedule) do
        :no_specified -> {user, _} = List.first users
                          user
                 user -> user
      end

    {:reply, {:ok, Atom.to_string(manager)}, state}
  end

  def handle_call({:when?, user}, _from, {schedule, _, _} = state) do
    {fullName, startDate} = Keyword.get(schedule, String.to_atom(user), {:invalid_user, :no_specified})
    {:reply, {:ok, fullName, startDate}, state}
  end


  def handle_call(:set_manager_of_the_week, _from, {schedule, users, _} ) do
    {schedule, manager} =
      case get_manager_of_week(schedule) do
        :no_specified -> sch = build_schedule(users, Date.utc_today)
                         man = get_manager_of_week(sch)
                         {sch, man}
              manager -> {schedule, manager}
    end
    fullName = Keyword.get(users, manager, :no_specified)
    {:reply, {:ok, fullName}, {schedule, users, manager}}
  end

  def handle_call(:schedule, _from, {schedule, _,_} = state) do
    {:reply, {:ok, schedule}, state}
  end

  def handle_call({:create_schedule, startDate}, _from, {_, users, _}) do

    {:ok, startDate} = startDate
                       |> String.trim()
                       |> Date.from_iso8601()

    schedule = build_schedule(users, startDate)
    save_state(schedule, @schedule_file)
    manager = get_manager_of_week(schedule)
    {:reply, {:ok, schedule}, {schedule, users, manager}}
  end

  def handle_call({:add_user, user, fullname}, _from,  {schedule, users, manager}) do
    fullname = buildFullName(fullname)
    user = user
           |> String.trim()
           |> String.to_atom()

    users = Keyword.put_new(users, user, fullname)
    schedule = add_to_schedule(schedule, user, fullname)
    save_state(schedule, @schedule_file)
    save_state(users, @users_file)
    {:reply, :ok, {schedule, users, manager}}
  end


  def handle_call({:remove_user, user}, _from, {schedule, users, manager}) do
    user = user
           |> String.trim()
           |> String.to_atom()

    userList = Keyword.delete(users, user)
    save_state(userList, @users_file)

    {:reply, :ok, {schedule, userList, manager}}
  end

  def handle_call({:swap, _userA, _userB}, _from, {[], users, manager}) do
    {:reply, {:error, "There is no schedule ready. Use the command 'help' for more information."}, {schedule, users, manager}}
  end

  def handle_call({:swap, userA, userB}, _from, {schedule, users, manager}) do
    userA = userA
           |> String.trim()
           |> String.to_atom()

    userB = userB
            |> String.trim()
            |> String.to_atom()

    case validate_user_names([userA, userB], users) do
      true ->
              {nameA, dateA} = Keyword.get(schedule, userA)
              {nameB, dateB} = Keyword.get(schedule, userB)

              newSchedule = schedule
                |> Keyword.replace!(userA, {nameA, dateB})
                |> Keyword.replace!(userB, {nameB, dateA})

              save_state(newSchedule, @schedule_file)
              manager = get_manager_of_week(newSchedule)
              {:reply, :ok, {newSchedule, users, manager}}

      msg -> {:reply, {:error, msg}, {schedule, users, manager}}

    end
  end

  def handle_call(:remove_users, _from, _state) do
    save_state([], @users_file)
    save_state([], @schedule_file)
    {:reply, :ok, {[], [], :no_specified}}
  end

  def handle_call(:remove_schedule, _from, {_, users, _}) do
    save_state([], @schedule_file)
    {:reply, :ok, {[], users, :no_specified}}
  end


  ###########
  # Private #
  ###########

  defp save_state(data, file) do
    content = :io_lib.format("~tp.~n", [data])
    :ok     = :file.write_file(file, content)
  end

  defp restore_state() do
    usersData = :file.consult(@users_file)
    scheduleData = :file.consult(@schedule_file)

    users = case usersData do
        {:ok, [values]} -> values
      _               -> []
    end

    schedule = case scheduleData do
      {:ok, [values]} -> values
      _               -> []
    end

    manager = get_manager_of_week(schedule)

    {:ok, {schedule, users, manager}}
  end

  defp buildFullName(fullName, acc \\ "")
  defp buildFullName([], acc) do
    String.trim(acc)
  end
  defp buildFullName([h|rest], acc) do
    acc = acc <> " " <> h
    buildFullName rest, acc
  end

  defp add_to_schedule([] = schedule, _user, _fullName), do: schedule

  defp add_to_schedule(schedule, user, fullName) do
    {_, {_, lastDate}} = Enum.max_by(schedule, fn({u, {f, date}}) -> date end)
    Keyword.put(schedule, user, {fullName, get_next_valid_date(Date.add(lastDate, 7))})
  end

  defp  validate_user_names([], _users), do: true
  defp  validate_user_names([user| rest], users) do
    case Keyword.has_key?(users, user) do
       false -> "Invalid username! The user #{user} is not a registered."
       _     -> validate_user_names(rest, users)
    end
  end

  defp build_schedule(list, startDate, schedule \\ [])
  defp build_schedule([], _startDate, schedule), do:  Enum.reverse(schedule)

  defp build_schedule([{k, v} | rest], startDate, schedule) do
    startDate = get_next_valid_date(startDate)
    schedule = Keyword.put_new(schedule, k, {v, startDate})
    nextDate = get_next_valid_date(Date.add(startDate, 7))
    build_schedule(rest,nextDate, schedule )
  end

  defp get_next_valid_date(date) do
    holiday? = Enum.find(@holidays, fn(x) -> Date.compare(date, x) == :eq end)
    case holiday? do
       nil -> get_start_date(date)
       _   -> get_next_valid_date(Date.add(date, 7))
    end
  end

  defp get_manager_of_week([]), do: :no_specified
  defp get_manager_of_week(schedule) do
    startDate = get_start_date()
    result = Enum.find(schedule, fn({k, {_, date}}) -> Date.compare(startDate, date) == :eq end)
    case result do
      nil      -> :no_specified
      {user,_} -> user
    end

  end

  defp get_next_manager([]), do: :no_specified
  defp get_next_manager(schedule) do
    startDate = Date.add(get_start_date, 7)
    result = Enum.find(schedule, fn({k, {_, date}}) -> Date.compare(startDate, date) == :eq end)
    case result do
      nil      -> :no_specified
      {user,_} -> user
    end
  end

  defp get_start_date( date \\ Date.utc_today) do
    case Date.day_of_week(date) do
       1     -> date
       value -> Date.add(date, -(value-1))
    end
  end

end
