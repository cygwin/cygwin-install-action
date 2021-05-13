Cygwin Install GitHub Action
============================

This GitHub Action can be used in a workflow to install Cygwin.

e.g.

    - run: git config --global core.autocrlf input

    - uses: actions/checkout@v2

    - uses: cygwin/cygwin-install-action@master

    - run: C:\cygwin\bin\bash.exe tests/script.sh

Please fix my terrible cargo-cult PowerShell.

Parameters
----------

| Input       | Default | Description
| ----------- | ------- | -----------
| platform    | x86_64  | Install the x86 or x86\_64 version of Cygwin.
| packages    | *none*  | List of additional packages to install.

Line endings
------------

If you're going to use `actions/checkout` in your workflow, you should
precede that with

    - run: git config --global core.autocrlf input

to ensure that any shell scripts etc. in your repository don't get checked out
with `\r\n` line endings (leading to `'\r': command not found` errors).

Likewise, if you have multiple lines of shell script in a YAML block for `run:`
in your workflow file, the file this is written into on the runner ends up with
`\r\n` line endings.

You can use `>-` (rather than `|`) to ensure that it doesn't contain any
newlines.

Alternatively, you can also use:

- `igncr` in the `SHELLOPTS` environment variable
- invoke `bash` with `-o igncr`

PATH
----

If you want to ensure that PATH only contains Cygwin executables, and other
stuff installed in the VM image isn't going to get picked up:

- Set PATH to something like `/usr/bin:$(cygpath ${SYSTEMROOT})/system32` in
  your shell script

or,

- Put `CYGWIN_NOWINPATH=1` into the environment
- start a login shell with `bash --login`
- because the profile script from does `cd ${HOME}`, either:
  * `cd ${GITHUB_WORKSPACE}` in your shell script, or
  * prevent the profile script from changing directory by putting
    `CHERE_INVOKING` into the environment

Symlinks
--------

Unfortunately, Cygwin's `setup` doesn't (currently) honour
`CYGWIN=winsymlinks:native` or offer an option to control the kind of symlinks
created, so some executables (e.g. `python`) are created as Cygwin-style
symlinks. Since CMD and PowerShell don't understand those symlinks, you cannot
run those executables directly in a `run:` in your workflow. Execute them via
`bash` or `env` instead.

[1] The
[Workflow documentation](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#exit-codes-and-error-action-preference)
suggests you should also use bash options `-eo pipefail`, omitted here for clarity
