defmodule HomeAutomation.Device do
  alias HomeAutomation.Network
  alias HomeAutomation.EventQueue
  alias __MODULE__
  require Logger
  use Agent

  defstruct [:name, :ip, :mac, :vendor, :last_seen, online: false]

  def start_link(opts) do
    result = Agent.start_link(fn -> [] end, opts)

    spawn_link(fn -> schedule_check_online() end)

    result
  end

  defp schedule_check_online do
    check_online()
    Process.sleep(30000)
    schedule_check_online()
  end

  defp check_online do
    hosts =
      Network.list_hosts()
      |> Enum.filter(fn host -> host.mac != nil and host.mac != "" end)

    Agent.update(Device, fn devices ->
      new = create_new_devices(devices, hosts)

      update_devices(devices ++ new, hosts)
    end)
  end

  defp update_devices(devices, hosts) do
    # update device online status
    Enum.map(devices, fn device ->
      host = Enum.find(hosts, fn host -> host.mac == device.mac end)
      online = host != nil

      should_update = online or can_go_offline(device)

      if should_update, do: update_device(device, online, host), else: device
    end)
  end

  defp can_go_offline(%Device{ip: ip, last_seen: last_seen}) do
    # debounce going offline
    debounce_time = Application.get_env(:home_automation, :offline_debounce)

    (last_seen == nil or DateTime.diff(DateTime.utc_now(), last_seen) > debounce_time) and
      (ip == nil or not Network.reachable?(ip))
  end

  defp update_device(device, online, host) do
    was_online = device.online
    old_device = device

    device =
      if online do
        %{
          device
          | ip: host.ipv4,
            vendor: host.vendor,
            online: true,
            last_seen: DateTime.utc_now()
        }
      else
        %{device | online: false}
      end

    if online != was_online do
      new_state = if online, do: :online, else: :offline
      Logger.info("#{displayname(device)} went #{to_string(new_state)}")
      # todo: check if complete old device is required
      EventQueue.call([:device, new_state, device, old_device])
    end

    device
  end

  defp create_new_devices(devices, hosts) do
    known_devices = Application.get_env(:home_automation, :known_devices, %{})
    device_macs = Enum.map(devices, fn device -> device.mac end)

    hosts
    # find out if device is already known by mac
    |> Enum.filter(fn host -> host.mac not in device_macs end)
    |> Enum.map(
      &%Device{
        ip: &1.ipv4,
        mac: &1.mac,
        vendor: &1.vendor,
        name: get_in(known_devices, [&1.mac, :name])
      }
    )
    |> Stream.each(&EventQueue.call([:device, :new, &1]))
    |> Enum.to_list()
  end

  defp displayname(%Device{name: name, mac: mac, ip: ip}) do
    Enum.find([name, mac, ip], fn value -> value != nil and value != "" end)
  end

  @doc """
  return all known devices
  """
  @spec list_devices() :: [%Device{}]
  def list_devices do
    Agent.get(Device, fn devices -> devices end)
  end

  @spec find(String.t()) :: %Device{} | nil
  def find(name) do
    Agent.get(Device, &Enum.find(&1, fn device -> device.name == name end))
  end

  @spec offline_duration(%Device{online: boolean, last_seen: DateTime}) :: non_neg_integer
  def offline_duration(%Device{online: online, last_seen: last_seen}) do
    cond do
      online -> 0
      last_seen == nil -> 0
      true -> div(DateTime.diff(DateTime.utc_now(), last_seen, :second), 60)
    end
  end

  @spec set_name(String.t(), String.t()) :: :ok
  def set_name(mac, name) do
    Agent.update(Device, fn devices ->
      index = Enum.find_index(devices, fn device -> device.mac == mac end)
      List.update_at(devices, index, fn device -> %Device{device | name: name} end)
    end)
  end
end
