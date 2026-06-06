
Never make changes to git - no git add, no git commit. When you add files, show me the git add command that I can execute myself.

Whenever you generate code that can make changes to the database, also include code for logging these changes in the audit log.
We always maintain the invariant that the db content can be fully reconstructed from the audit log.
