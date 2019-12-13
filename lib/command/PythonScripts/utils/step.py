import time
from contextlib import contextmanager
from utils.logger import logger


@contextmanager
def step(name, path_to_save_step_time=None):
  start = time.time()
  logger.info('Step started: {}'.format(name))
  try:
    yield
  finally:
    time_spent_in_seconds = time.time() - start
    time_spent_in_minutes = time_spent_in_seconds / 60.0
    logger.info('Step finished: {}. Time spent: {:.1f} s ~ {:.1f} m'.format(
      name, time_spent_in_seconds, time_spent_in_minutes
    ))

    if path_to_save_step_time:
      with open(path_to_save_step_time, 'a') as f:
        f.write('%-30s | %-10s ≈ %.2f m\n' % (
          name,
          '%d s' % time_spent_in_seconds,
          time_spent_in_minutes
        ))
