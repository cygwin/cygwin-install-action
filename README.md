Cygwin Install GitHub Action
============================

This GitHub Action can be used in a workflow to install Cygwin.

e.g.

```yaml
- run: git config --global core.autocrlf input
- uses: actions/checkout@v6

- uses: cygwin/cygwin-install-action@v6
  with:
    packages: |
      git
      python3
      python3-pip

- run: bash tests/script.sh  # see note below
```

> [!NOTE]
>
> The [Workflow documentation][github-workflow-documentation]
> suggests you should also use bash options `-eo pipefail`.
> It's omitted here for clarity.


Table of Contents
-----------------

* [Inputs](#inputs)

  * [`packages`](#packages)
  * [`error-on-missing-packages`](#error-on-missing-packages)
  * [`allow-test-packages`](#allow-test-packages)
  * [`work-vol`](#work-vol)
  * [`install-dir`](#install-dir)
  * [`platform`](#platform)
  * [`add-to-path`](#add-to-path)
  * [`site`](#site)
  * [`pubkeys`](#pubkeys)
  * [`check-hash`](#check-hash)
  * [`check-installer-sig`](#check-installer-sig)
  * [`check-sig`](#check-sig)

* [Outputs](#outputs)

  * [`root`](#root)
  * [`setup`](#setup)
  * [`package-cache`](#package-cache)

* [Line endings](#line-endings)
* [PATH](#path)
* [Symlinks](#symlinks)
* [Mirrors and signatures](#mirrors-and-signatures)


Inputs
------

### `packages`

A list of additional packages to install.

Example usage:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    packages: |
      git
      python3
      python3-pip
```

### `error-on-missing-packages`

By default, if any packages in the [`packages`](#packages) input
cannot be found, the action will fail.

Errors can be downgraded to warnings by setting this input to `'false'`.
This may be useful when Cygwin transitions from one package to another
for equivalent functionality.

Example usage:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    packages: |
      package10
      alternate-package10
    error-on-missing-packages: 'false'
```

### `allow-test-packages`

By default, packages marked test are not considered for installation.

Setting this input to `'true'` will allow test packages
to be found and installed.

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    allow-test-packages: 'true'
    packages: |
      my-cool-package
```

### `work-vol`

The Windows volume to which the installer and packages are downloaded.

By default, `work-vol` is also the volume where Cygwin will be installed,
but the install location can be customized using the
[`install-dir`](#install-dir) input.

The default value is `'D:'` for performance reasons.

Example:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    work-vol: 'C:' # This affects the Cygwin install directory, too.
```

### `install-dir`

The absolute path to the directory where Cygwin will be installed.

The default install directory is `'D:\cygwin'`,
which is calculated using the [`work-vol`](#work-vol) input.

Example:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    install-dir: 'D:\cygwin64'
```

### `platform`

Select the architecture to install.

`'x86_64'` is the default value, but `'x86'` can also be specified.

> [!NOTE]
>
> Cygwin no longer supports the `'x86'` architecture.
>
> If `platform: 'x86'` is set, the [`site`](#site) input will change defaults
> to select the final 2022-11-23 archive of `'x86'` Cygwin, and the
> `--allow-unsupported-windows` option will be passed to the installer.
>
> Please refer to the Cygwin Installation documentation regarding
> [the limitations of Cygwin on the x86 architecture][unsupported].

Example usage:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    platform: 'x86_64'
```

### `add-to-path`

By default, Cygwin's `/usr/bin` directory is added to the system `$PATH`.

This behavior can be disabled by setting this input to `'false'`.

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    add-to-path: 'false'
```

### `site`

Mirror sites to install from, separated by whitespace.

The default site is selected based on the value of the [`platform`](#platform):

| `platform` | `site` default                                                  |
|------------|-----------------------------------------------------------------|
| `'x86_64'` | `https://mirrors.kernel.org/sourceware/cygwin/`                 |
| `'x86'`    | `https://mirrors.kernel.org/sourceware/cygwin-archive/20221123` |

Example:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    site: |
      https://mirrors.kernel.org/sourceware/cygwin/
      https://domain.example/path/
```

### `pubkeys`

Absolute paths to extra public key files (RFC4880 format).

Example:

```yaml
# Prior to reaching this step in the workflow
# you would need to download the keys referenced below.
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    pubkeys: |
      D:\key1.pub
      D:\key2.pub
```

### `check-hash`

By default, the hash of the Cygwin installer will be verified.

This behavior can be disabled by setting this input to `'false'`.

> [!WARNING]
>
> Disabling hash verification may create a security risk.
>
> Only disable this if you are very confident
> that this is appropriate and necessary.

Example:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    check-hash: 'true'  # Change to 'false' only if required.
```

### `check-installer-sig`

By default, the Authenticode signature of the installer file will be verified.

This behavior can be disabled by setting this input to `'false'`.

> [!WARNING]
>
> Disabling signature verification may create a security risk.
>
> Only disable this if you are very confident
> that this is appropriate and necessary.

Example:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    check-installer-sig: 'true'  # Change to 'false' only if required.
```

### `check-sig`

By default, the installer will verify the signature of the package manifest.

This behavior can be disabled by setting this input to `'false'`.

> [!WARNING]
>
> Disabling signature verification may create a security risk.
>
> Only disable this if you are very confident
> that this is appropriate and necessary.

Example:

```yaml
- uses: 'cygwin/cygwin-install-action@<version>'
  with:
    check-sig: 'true'  # Change to 'false' only if required.
```


Outputs
-------

### `root`

The root directory of the Cygwin installation.

By default, this value will be `'D:\cygwin'`, but it is affected by the
[`work-vol`](#work-vol) and [`install-dir`](#install-dir) options.

### `setup`

The absolute path to the Cygwin installer.

### `package-cache`

The absolute path to the package cache directory.


Line endings
------------

### in the checkout

If you're going to use `actions/checkout` in your workflow, you should
precede that with

    - run: git config --global core.autocrlf input

to ensure that any shell scripts etc. in your repository don't get checked out
with `\r\n` line endings (leading to `'\r': command not found` errors).

### in the workflow

Likewise, if you have multiple lines of shell script in a YAML block for `run:`
in your workflow file, the file this is written into on the runner ends up with
`\r\n` line endings.

You can use `>-` (rather than `|`) to ensure that it doesn't contain any
newlines.

Alternatively, you can invoke `bash` with `-o igncr`.

**Warning:**
Putting `igncr` in the `SHELLOPTS` environment variable seems like it should
have the same effect, but this can have unintended side-effects (by default,
`SHELLOPTS` is a shell variable and moving it to the environment causes **all**
shell options to propagate to child shells).


PATH
----

By default, this action prepends Cygwin's `/usr/bin` directory to the PATH.

If you do not want the system PATH changed,
set [`add-to-path`](#add-to-path) to `'false'`.

### A clean PATH

However, if you want to ensure that PATH only contains Cygwin executables,
and other stuff installed in the VM image isn't going to get picked up:

- Set PATH to something like `/usr/bin:$(cygpath ${SYSTEMROOT})/system32` in
  your shell script

or,

- Put `CYGWIN_NOWINPATH=1` into the environment
- start a login shell with `bash --login`
- because the profile script does `cd ${HOME}`, either:
  * `cd ${GITHUB_WORKSPACE}` in your shell script, or
  * prevent the profile script from changing directory by putting
    `CHERE_INVOKING` into the environment


Symlinks
--------

Cygwin's installer creates Cygwin-style symlinks by default, and some
executables (e.g. `python`) are symlinks.

Since CMD and PowerShell don't understand those symlinks, you cannot run
those executables directly in a `run:` in your workflow. Execute them via
`bash` or `env` instead.

Alternatively, putting e.g. `CYGWIN=winsymlinks:native` into the workflow's
environment works, since the installer now honours that.


Mirrors and signatures
----------------------

You probably don't need to change the setting for [`site`](#site),
and you shouldn't change [`check-hash`](#check-hash),
[`check-installer-sig`](#check-installer-sig), or [`check-sig`](#check-sig)
unless you're very confident it's appropriate and necessary.

These options are very unlikely to be useful except in some very isolated
circumstances, such as using the [Cygwin Time Machine][cygwin-time-machine].


[github-workflow-documentation]: https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#exit-codes-and-error-action-preference
[cygwin-time-machine]: http://www.crouchingtigerhiddenfruitbat.org/Cygwin/timemachine.html
[unsupported]: https://cygwin.com/install.html#unsupported
