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

Many guides still show how to generate RSA keys. The modern alternative for a while has been ED25519, but GPG hides it in the advanced key generation options. To use it, start with:

### master key

```bash
gpg --full-generate-key --expert
```

This will ask you to pick a specific key. Type '11' to use ECC and manually select capabilities.

```
Please select what kind of key you want:
   (1) RSA and RSA
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
   (9) ECC (sign and encrypt) *default*
  (10) ECC (sign only)
  (11) ECC (set your own capabilities)
  (13) Existing key
  (14) Existing key from card
Your selection? 11
```

Next (and confusingly), GPG is telling you that the key will have Sign and Certify capabilities by default. To disable or enable them, you can 'toggle' the capability by typing the letter next to the listed entry. 

Type 'S' and hit Enter to disable the Sign capability. This will leave the key with only the Certify capability, so you can type 'Q' to finish this step.

```
Possible actions for this ECC key: Sign Certify Authenticate
Current allowed actions: Sign Certify

   (S) Toggle the sign capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? S

Possible actions for this ECC key: Sign Certify Authenticate
Current allowed actions: Certify

   (S) Toggle the sign capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? Q
```

Then, GPG provides a list of curve algorithms to pick. The default is the desired one, Curve 25519.

```
Please select which elliptic curve you want:
   (1) Curve 25519 *default*
   (2) Curve 448
   (3) NIST P-256
   (4) NIST P-384
   (5) NIST P-521
   (6) Brainpool P-256
   (7) Brainpool P-384
   (8) Brainpool P-512
   (9) secp256k1
Your selection? 1
```

You can specify when the key will expire. Generally, since GPG relies on a 'web of trust' where people hold onto your key for a long time, you want your root level key to rarely expire. It will also have no abilities, existing solely to sign subkeys that you actually use for day-to-day work.

Some leave it at 10 years, you can also make it never expire.

```
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)
Key does not expire at all
Is this correct? (y/N) y
```

At the penultimate step, GPG asks you to fill out an identity. You can go all out here or just specify your username - but keep in mind that for commits to appear as valid on websites such as Github, the email here must match one of your verified Github emails.

```
GnuPG needs to construct a user ID to identify your key.

Real name: Richard H. Pajerski II
Email address: richard.pjski2@proton.me
Comment: devedge
You selected this USER-ID:
    "Richard H. Pajerski II (devedge) <richard.pjski2@proton.me>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
```

Finally, it'll ask you to provide a password. If you followed the configuration steps in the first section, it'll only ask for it once, so be sure to type/paste it correctly.

### signing key

The signing key is a subkey of the master key, and they are both logically considered part of the same GPG key. To edit your existing key that you just created and add a subkey, run:

```bash
gpg --expert --edit-key devedge
```

A new prompt will appear, with the `gpg>` prefix. Type `addkey` and hit Enter:

```
gpg> addkey
```

Select `(11) ECC (set your own capabilities)` for the encryption algorithm, same as the first.

However, the key capabilities should already just be signing, so you can automatically select 'Q':

```
Current allowed actions: Sign

   (S) Toggle the sign capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? Q
```

The elliptic curve will be the same, `(1) Curve 25519 *default*`.

Next, you can specify the desired key validity time. To continue signing after this time has passed, you'll need to generate a new subkey again with the master key. The idea behind this is that if you've had your key copied/stolen somehow, it can't be used forever. However, in practice, if someone has enough access to your PC that they've got your GPG keys, you usually have much bigger problems to worry about.

I've set my expiry date to 5 years.

```
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 5y
Key expires at Tue Dec 18 20:29:05 2029 EST
Is this correct? (y/N) y
Really create? (y/N) y
```

This will create the key and automatically print info for both keys. The top section, marked with `sec` for Secret Key and `usage: C` for Certify, is the master key. Its key fingerprint is `5E88702C976C97B1`. The lower section, marked with `ssb` for the Subkey certified by the master key, has `usage: S` for Signing and has a fingerprint of `882630A8E2F9526B`.

```
sec  ed25519/5E88702C976C97B1
     created: 2024-12-20  expires: never       usage: C
     trust: ultimate      validity: ultimate
ssb  ed25519/882630A8E2F9526B
     created: 2024-12-20  expires: 2029-12-19  usage: S
[ultimate] (1). Richard H. Pajerski II (devedge) <richard.pjski2@proton.me>
```

To apply the changes, be sure to type `save` and hit enter. This also automatically quits the pseudo-prompt, so either be sure to finish completing all your changes, or you'll have to re-enter the key editor with the command at the top of this subsection.

```
gpg> save
```

## list your keys

There are endless ways to list your keys and all the information they provide, but I've found that you generally don't need to worry about most of it. Regardless of how many subkeys your GPG key has, referencing either the master key's ID or any part of your UID will allow GPG to pick the appropriate subkey. If you have multiple subkeys with the same function, GPG picks the most recently created one.

However, here's a few commands that I've found useful:

The default:

```
$ gpg --list-keys devedge
[keyboxd]
---------
pub   ed25519 2024-12-20 [C]
      55BE5089F634003042AE70985E88702C976C97B1
uid           [ultimate] Richard H. Pajerski II (devedge) <richard.pjski2@proton.me>
sub   ed25519 2024-12-20 [S] [expires: 2029-12-19]
```

Same as above, but with the master key ID split into 4-character chunks:
```
$ gpg --fingerprint devedge
[keyboxd]
---------
pub   ed25519 2024-12-20 [C]
      55BE 5089 F634 0030 42AE  7098 5E88 702C 976C 97B1
uid           [ultimate] Richard H. Pajerski II (devedge) <richard.pjski2@proton.me>
sub   ed25519 2024-12-20 [S] [expires: 2029-12-19]
```

List your key with all its subkey fingerprints:

```
$ gpg --list-keys --with-subkey-fingerprints devedge
pub   ed25519 2024-12-20 [C]
      55BE5089F634003042AE70985E88702C976C97B1
uid           [ultimate] Richard H. Pajerski II (devedge) <richard.pjski2@proton.me>
sub   ed25519 2024-12-20 [S] [expires: 2029-12-19]
      AE9E8E56437D11587FAFE840882630A8E2F9526B
```

Running the same command as above but with `--keyid-format LONG` adds the shortened fingerprint right after the algorithm, eg. `ed25519/5E88702C976C97B1`:

```
$ gpg --list-keys --with-subkey-fingerprints --keyid-format LONG devedge
pub   ed25519/5E88702C976C97B1 2024-12-20 [C]
      55BE5089F634003042AE70985E88702C976C97B1
uid                 [ultimate] Richard H. Pajerski II (devedge) <richard.pjski2@proton.me>
sub   ed25519/882630A8E2F9526B 2024-12-20 [S] [expires: 2029-12-19]
      AE9E8E56437D11587FAFE840882630A8E2F9526B
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
+QEAosZC3I3kQD/pmIzupZbwROyDjYp4utqlPOS3uCC4PQg=
=j1+T
-----END PGP PUBLIC KEY BLOCK-----
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
git config --local user.signingkey richard.pjski2@proton.me
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
