import subprocess


class Shell:
  """A class to work with Shell commands."""

  class RunError(BaseException):
    """Error/Exception when running Shell commands."""
    pass

  @staticmethod
  def run(cmd):
    """Run a shell command. Return the output of the command.
    If error occurred while running this command, yield an error of type Shell.RunError.
    """

    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = proc.communicate()

    if isinstance(output, bytes):  # For python 3
      output = output.decode('utf-8')
    if isinstance(error, bytes):   # For python 3
      error = error.decode('utf-8')
    output, error = output.strip(), error.strip()

    if proc.returncode != 0:
      raise Shell.RunError('{}. Exit code {}'.format(error, proc.returncode))
    return output

  @staticmethod
  def osascript(script):
    cmd = 'osascript -e \'{}\''.format(script)
    return Shell.run(cmd)
