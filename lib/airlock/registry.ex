defmodule Airlock.Registry do
  use GenServer

  def start_link(_options) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def init(_options) do
    {:ok, []}
  end

  def count() do
    Registry.count(__MODULE__)
  end

  def keys() do
    Registry.keys(__MODULE__, self())
  end

  def lookup(key) do
    Registry.lookup(__MODULE__, key)
  end

  def via(name) do
    {:via, Registry, {__MODULE__, name}}
  end
end
