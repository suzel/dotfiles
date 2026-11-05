# Workflows

- Keep going without stopping to check in, unless you truly need me or the next step is destructive.
- Time matters here: do not spend time that can be avoided, and the earlier a correct result is
  obtained, the better.
- Once you have answered something, treat that answer as done. On later turns, focus on what I'm
  asking now, and don't go back over an earlier answer unless I ask about it, point out a problem
  with it, or a later step shows it was wrong.
- Before changing code, read what the change touches, including callers, tests and config the task
  doesn't mention, but change only what the task needs; mention unrelated issues instead of fixing
  them.
- Write the minimum code that solves the problem: no unrequested features, options or abstractions.
- Decide up front how you'll check the result is correct, and check it before calling it done.
- When a test fails after your change, find the root cause before changing code or tests, and
  assume the code is wrong, not the test. Never weaken an assertion, skip or delete a test, or
  special-case code for test inputs just to make it pass. Change a test only when the task changes
  the behavior it checks or it is shown to be wrong, and say why.
- Create and edit files with Write/Edit, not Bash (`sed -i`, `>`, heredoc).
