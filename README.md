Cygwin Install GitHub Action
============================

This GitHub Action can be used in a workflow to install Cygwin.

e.g.

    - run: git config --global core.autocrlf input

    - uses: actions/checkout@v2

    - uses: cygwin/cygwin-install-action@master

    - run: bash tests/script.sh  # see footnote [1]

Please fix my terrible cargo-cult PowerShell.

Parameters
----------

| Input         | Default                                      | Description
| ------------- | -------------------------------------------- | -----------
| platform      | x86_64                                       | Install the x86 or x86\_64 version of Cygwin.
| packages      | *none*                                       | List of additional packages to install.
| install-dir   | C:\cygwin                                    | Installation directory
| site          | http://mirrors.kernel.org/sourceware/cygwin/ | Mirror site to install from
| check-sig     | true                                         | Whether to check the setup.ini signature
| add-to-path   | true                                         | Whether to add Cygwin's `/bin` directory to the system `PATH`
| package-cache | disabled                                     | Whether to cache the package downloads

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

By default, this action prepends Cygwin's /usr/bin directory to the PATH.

However, if you want to ensure that PATH only contains Cygwin executables,
and other stuff installed in the VM image isn't going to get picked up:

- Set PATH to something like `/usr/bin:$(cygpath ${SYSTEMROOT})/system32` in
  your shell script

or,

- Put `CYGWIN_NOWINPATH=1` into the environment
- start a login shell with `bash --login`
- because the profile script from does `cd ${HOME}`, either:
  * `cd ${GITHUB_WORKSPACE}` in your shell script, or
  * prevent the profile script from changing directory by putting
    `CHERE_INVOKING` into the environment

If you want the opposite – the system PATH to remain unchanged by this action – add `add-to-path: false` to the action settings.

Symlinks
--------

Cygwin's `setup` creates Cygwin-style symlinks by default, and some
executables (e.g. `python`) are symlinks.

Since CMD and PowerShell don't understand those symlinks, you cannot run
those executables directly in a `run:` in your workflow. Execute them via
`bash` or `env` instead.

Alternatively, putting e.g. `CYGWIN=winsymlinks:native` into the workflow's
environment works, since setup now honours that.

Caching
-------

If you're likely to do regular builds, you might want to store the packages
locally rather than needing to download them from the Cygwin mirrors on every
build.  Set `package-cache` to `enabled` and the action will use [GitHub's
dependency caching][0] to store downloaded package files between runs.

[0]: https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows

This has the effect of speeding up the run of the installation itself, at the
expense of taking slightly longer before and after the installation to check
and potentially update the cache.  The installer will still check for updated
packages, and will download new packages if the cached ones are out of date

In certain circumstances you might want to ignore any existing caches but still
store a new one, or restore a cache but not write one.  Do this by setting
`package-cache` to `saveonly` or `restoreonly` as appropriate.  This is
particularly useful when calling the action multiple times in the same run,
where you probably want to restore the cache the first time the action is
called, then save it the last time it is called.

You should make sure to clear these caches every so often.  This action, like
the underlying Cygwin installer, doesn't remove old package files from its
download directory, so if you don't clear the caches occasionally (and you run
builds often enough that GitHub doesn't do it for you automatically) you'll
find the caches keep getting larger as they gain more and more outdated and
unused packages.  Either [delete them manually][1], [use a separate action or
API call][2], or do occasional runs with `saveonly` to create a fresher small
cache.

[1]: https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#deleting-cache-entries
[2]: https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#deleting-cache-entries

Mirrors and signatures
----------------------

You probably don't need to change the setting for `site`, and you shouldn't
change `check-sig` unless you're very confident it's appropriate and necessary.
These options are very unlikely to be useful except in some very isolated
circumstances, such as using the [Cygwin Time
Machine](http://www.crouchingtigerhiddenfruitbat.org/Cygwin/timemachine.html).

[1] The
[Workflow documentation](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#exit-codes-and-error-action-preference)
suggests you should also use bash options `-eo pipefail`, omitted here for clarity
