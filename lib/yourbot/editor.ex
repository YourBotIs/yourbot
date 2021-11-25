defmodule YourBot.Editor do
  def format(code) do
    filename = Path.join(System.tmp_dir!(), Ecto.UUID.generate())
    File.write!(filename, code)
    {"", 0} = System.cmd("python3", ["-m", "black", "-q", filename])
    formatted = File.read!(filename)
    File.rm!(filename)
    {:ok, formatted}
  end
end
