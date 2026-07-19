+++
title = "Deleting Sequoia-PGP certificates"
date = "2026-05-21 00:51:02"

[taxonomies]
tags = ["macOS", "gpg"]
+++


If you have been messing around with the potential GPG replacement command-line tool [Sequoia-PGP](https://sequoia-pgp.org/), you may have noticed that there doesn't appear to be a way to delete 'certs' from the certificate store.

After spending some time digging in the manpages and documentation with no clarification, it appears that this isn't a mistake but a matter of opinion. The developers treat the certificate store as a completely intentional append-only list, and an issue created about this was [closed as "won't complete" 3 years ago](https://gitlab.com/sequoia-pgp/pgp-cert-d/-/work_items/33).

This means that if you were experimenting with creating/deleting keys and certs or importing external certs, your certificate store will become littered with unused or broken certs with no possibility to clean it up (this could even be considered a privacy risk, since the default stance is to automatically "hide" them from users).

Unfortunately, if you are at this point, the only solution is nuclear - wipe the entire certstore and start over. Before moving forwards however, be sure to back up your certs & keys.


## Backing up keys & certs

First, export your full keys, as they are also listed in the cert output. List them with:

```bash
sq key list
```

and then export them with:

```bash
sq key export --cert KEYFINGERPRINT --output examplename.key.asc
```

Next, export any certs that you want to keep and re-import. List them with:

```bash
sq cert list
```

and export with

```bash
sq cert export --cert KEYFINGERPRINT --output examplename.cert.asc
```

The original documentation for these steps can be found here:

- [Exporting Keys](https://book.sequoia-pgp.org/key_export_import.html#export-a-key)
- [Exporting Certs](https://book.sequoia-pgp.org/cert_import_export.html)


## Wiping everything

To find where Sequoia-PGP is storing its configurations, run:

```bash
sq config inspect paths
```

On macOS, these will be in an entirely different location than indicated [in the documentation](https://book.sequoia-pgp.org/files.html).

Certificate Store:

```
/Users/YOURUSERNAME/Library/Application Support/pgp.cert.d
```

Keystore:

```
/Users/YOURUSERNAME/Library/Application Support/org.Sequoia-PGP.sequoia/keystore
```

Navigate to these directories and delete everything. You can confirm that this worked by running `sq cert list` and `sq key list` - no keys or certificates should show up.

{% note(title="Note") %}
If you have GNUPG set up, Sequoia-PGP will automatically pick up keys in the `~/.gnupd/` directory
{% end %}

## Re-import keys & certs

Importing is straightforwards:

```bash
sq key import examplename.key.asc
sq cert import examplename.cert.asc
```


## Workaround

A clunky workaround that was proposed in the above GitLab issue was creating a temporary configuration directory. By setting the `SEQUOIA_HOME` variable to this temporary directory (eg., with `export SEQUOIA_HOME=$HOME/.tmp-sequoia-data`), you can delete the directory later. 

Ultimately however, this isn't a real solution to proper certificate management, so GnuPG will remain my default choice for now.
