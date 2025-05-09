---
title: creating ed25519 gpg keys to sign git commits
date: 2024-12-27 16:14:30
tags:
    - gpg
---

While there's plenty of guides that try to give a full rundown of GPG and how it works, this is just a straightforwards breakdown for creating and using a new GPG key using proper modern defaults (the long breakdown may come later).

What GPG is used for in Git is _signing_ commits. No encryption/decryption necessary.

As a result, we'll be generating:

- A master key with no expiration date, which can be used to certify any new subkeys
- A subkey for signing, with an expiration date of 5 years
- (_optionally_) An encryption key for future use

## tl;dr

```bash
export KEYUID='Firstname Lastname (devedge) <firstname.lastname@email.com>'
gpg --quick-generate-key "$KEYUID" ed25519 cert never
gpg --quick-add-key KEYFINGERPRINTFROMABOVE ed25519 sign 5y
git config --local user.signingkey devedge
git config --local commit.gpgsign true
```

## first things first

The system and version I'm running is:

SoC: Apple M3 Pro
gpg (GnuPG) 2.4.7
libgcrypt 1.10.3

GPG was installed using [Homebrew](https://brew.sh/) (`brew install gnupg`)

To avoid incomprehensible errors like this:

```
error: gpg failed to sign the data:
[GNUPG:] KEY_CONSIDERED 55BE5089F634003042AE70985E88702C976C97B1 0
[GNUPG:] BEGIN_SIGNING H10
[GNUPG:] PINENTRY_LAUNCHED 60797 curses 1.3.1 - alacritty - - 501/20 0
gpg: signing failed: Inappropriate ioctl for device
[GNUPG:] FAILURE sign 83918950
gpg: signing failed: Inappropriate ioctl for device

fatal: failed to write commit object
```

you need to add this to `~/.gnupg/gpg.conf`:

```
use-agent
pinentry-mode loopback
```

and this to `~/.gnupg/gpg-agent.conf`:

```
allow-loopback-pinentry
```

And then run:

```bash
echo RELOADAGENT | gpg-connect-agent
```

in your terminal to reload the GPG agent. (Thanks to [Daniel15's post](https://d.sb/2016/11/gpg-inappropriate-ioctl-for-device-errors))

Why?

From what I can gather, GPG considers passwords typed over stdin on the CLI to be insecure. Rather than utilizing existing tools such as `sudo`, they wrote their own, `pinentry`. However, instead of making things more secure, this complication and associated incomprehensible error messages drives users to avoid using GPG at all (this is a very common theme with GPG).

You could also install another program, `pinentry-mac`, but this will open up an annoying popup window every single time GPG needs your password. The above solution will force GPG to use your terminal, just like every other application. If you would like to install `pinentry-mac` however, [this blog post is a good starting point](https://velvetcache.org/2023/03/26/a-peek-inside-pinentry/).

## generating the gpg keys

Many guides still show how to generate RSA keys. However, the modern alternative for a while has been ED25519. To use it, run:

### master key

```bash
gpg --quick-generate-key '<User ID>' ed25519 cert never
```

This generates a Certify-only (`cert`) `ed25519` key that `never` expires.

The `<User ID>` can generally be anything. The standard format follows the convention of:

`
Your Name (comment) <your.email@address.com>
`

However, keep in mind that for commits to appear as valid on websites such as Github, you need to include an email that matches one of your verified Github emails. The angle brackets surrounding the email (`< >`) are required.

Once you hit Enter, it'll ask you to provide a password. If you followed the configuration steps in the first section, it'll only ask for it once, so be sure to type/paste it correctly.

GPG will then print the new key:

```
pub   ed25519 2024-12-20 [C]
      55BE5089F634003042AE70985E88702C976C97B1
uid           [ultimate] Firstname Lastname (devedge) <firstname.lastname@email.com>
```

The `[C]` stands for Certify. Generally, since GPG relies on a 'web of trust' where people hold onto your key for a long time, you want your root level key to rarely expire. It will also have no abilities, existing solely to sign subkeys that you actually use for day-to-day work.

### signing key

The signing key is a subkey of the master key, and they are both logically considered part of the same GPG key.

```bash
gpg --quick-add-key 55BE5089F634003042AE70985E88702C976C97B1 ed25519 sign 5y
```

This generates a Sign-only (`sign`) `ed25519` key that expires in 5 years (`5y`). The `55BE5...` string is the master key's full fingerprint, which was printed above.


To continue signing after this time has passed, you'll need to generate a new subkey again with the master key. The idea behind this is that if you've had your key copied/stolen somehow, it can't be used forever.

#### _Note on ed25519 encryption_

Adding an encryption key involves a very small change: instead of `ed25519`, you'll need to specify `cv25519` for the encryption algorithm:

```bash
gpg --quick-add-key 55BE5089F634003042AE70985E88702C976C97B1 cv25519 encr 5y
```

## listing keys

While there's numerous ways to list your keys, I've found that you generally don't need to worry about most of them. Regardless of how many subkeys your GPG key has, referencing either the master key's ID or any part of your UID will allow GPG to pick the appropriate subkey. If you have multiple subkeys with the same function, GPG picks the most recently created one.

However, here's a few I've found useful:

The default:

```
$ gpg --list-keys devedge
[keyboxd]
---------
pub   ed25519 2024-12-20 [C]
      55BE5089F634003042AE70985E88702C976C97B1
uid           [ultimate] Firstname Lastname (devedge) <firstname.lastname@email.com>
sub   ed25519 2024-12-20 [S] [expires: 2029-12-19]
sub   cv25519 2024-12-29 [E] [expires: 2029-12-28]
```

Same as above, but with the master key ID split into 4-character chunks:

```
$ gpg --fingerprint devedge
pub   ed25519 2024-12-20 [C]
      55BE 5089 F634 0030 42AE  7098 5E88 702C 976C 97B1
uid           [ultimate] Firstname Lastname (devedge) <firstname.lastname@email.com>
sub   ed25519 2024-12-20 [S] [expires: 2029-12-19]
sub   cv25519 2024-12-29 [E] [expires: 2029-12-28]
```

You can also go all-out and list each of the subkey fingerprints:

```
$ gpg --list-keys --with-subkey-fingerprints --keyid-format=LONG devedge
pub   ed25519/5E88702C976C97B1 2024-12-20 [C]
      55BE5089F634003042AE70985E88702C976C97B1
uid                 [ultimate] Firstname Lastname (devedge) <firstname.lastname@email.com>
sub   ed25519/882630A8E2F9526B 2024-12-20 [S] [expires: 2029-12-19]
      AE9E8E56437D11587FAFE840882630A8E2F9526B
sub   cv25519/258ADE692963C5B3 2024-12-29 [E] [expires: 2029-12-28]
      1C3C6C37E6E0248E5B54C0E8258ADE692963C5B3
```

Finally, to export your public key in ASCII plaintext to share, run:

```
$ gpg --armor --export devedge
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEZ2TErhYJKwYBBAHaRw8BAQdAzgjB3r552mWBwNhcdGZ+2G48SnhSoTWr5CzK
QfXxHre0O1JpY2hhcmQgSC4gUGFqZXJza2kgSUkgKGRldmVkZ2UpIDxyaWNoYXJk
LnBqc2tpMkBwcm90b24ubWU+iJMEExYKADsWIQRVvlCJ9jQAMEKucJheiHAsl2yX
sQUCZ2TIwwIbAQULCQgHAgIiAgYVCgkICwIEFgIDAQIeBwIXgAAKCRBeiHAsl2yX
sTMKAQCcrv1D1M8pWFnpTA+SSCZxK1RVk9x/CUit2Hv+1oPPbQEAnIgqoryLxrkh
wtt+OifSZzzhdN7qvcmJQbvkoq2MRwq4MwRnZMgtFgkrBgEEAdpHDwEBB0BA8iAQ
7zCdTB5/7HFzWXbbCUndzykTezhkpksoqtTH9Yj1BBgWCgAmFiEEVb5QifY0ADBC
rnCYXohwLJdsl7EFAmdkyC0CGwIFCQlmAYAAgQkQXohwLJdsl7F2IAQZFgoAHRYh
BK6ejlZDfRFYf6/oQIgmMKji+VJrBQJnZMgtAAoJEIgmMKji+VJrb+UA/iIF0zAc
LFKQbhzP6lY8GHfKd5mWKk2pjqG3E8HAErPlAP9MxH+qIF3FlpQB95Kog/oUh3EI
hX9M+helqM8mMhGBBv9dAQCl2jqJrrJY9py53LejlLZ0pzTwDQA7FdzoHWz/UJF7
+QEAosZC3I3kQD/pmIzupZbwROyDjYp4utqlPOS3uCC4PQi4OARncU/0EgorBgEE
AZdVAQUBAQdA3Bs/kDcYB3WVD+V2uk7L5w0968NSvgjmpPgMrv1ScBkDAQgHiH4E
GBYKACYWIQRVvlCJ9jQAMEKucJheiHAsl2yXsQUCZ3FP9AIbDAUJCWYBgAAKCRBe
iHAsl2yXsU12AP46i6XmHRcWJY6vMI36F0LLXfe/IyaFNFI28vA4iQeV/AEAvqAi
5/yO7vn/NItgMIfqC84ZeDirypv7f3y3LQq3xwU=
=ubLP
-----END PGP PUBLIC KEY BLOCK-----
```

Or directly exported to a file:

```bash
gpg --armor --export --output devedge.asc devedge
```

## signing commits with them

A good idea to ensure you never forget to sign commits is to run the command:

```bash
git config --local commit.gpgsign true
```

in the root directory of your git repository. This will add a configuration entry in `.git/config` for that repo, automatically requiring a signature for every commit. This is more convenient than having to manually type the `-S` flag to sign every `git commit` as a one-off.

To specify your new key for that repository, run one of the following:

```bash
# some part of the UID
git config --local user.signingkey devedge

# a different example using the email instead
git config --local user.signingkey firstname.lastname@email.com
```

You could also (confusingly) specify the key fingerprint or full key ID of either the master key or the signing key:

```bash
# master key fingerprint (last 16 characters of full key ID)
git config --local user.signingkey 5E88702C976C97B1

# full master key ID
git config --local user.signingkey 55BE5089F634003042AE70985E88702C976C97B1

# or likewise for the signing key:
git config --local user.signingkey 882630A8E2F9526B
git config --local user.signingkey AE9E8E56437D11587FAFE840882630A8E2F9526B
```

GPG will automatically pick the signing key you created. If you have multiple, it appears to use the most recently created one.

If you want to use this key globally for every repository on your machine, replace the `--local` flag with `--global`. This will place the configuration options in your home directory instead, inside `~/.gitconfig`.

---

## resources

- Git guide to signing your work: 
    https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work
- Github guide to using your GPG key with Github:
    https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key
- Fixing GPG "Inappropriate ioctl for device" errors:
    https://d.sb/2016/11/gpg-inappropriate-ioctl-for-device-errors
- Guide for `pinentry-mac`:
    https://velvetcache.org/2023/03/26/a-peek-inside-pinentry/
- Another article covering a slightly different solution to signing commits over ssh:
    https://ertt.ca/blog/2022/01-10-git-gpg-ssh/
