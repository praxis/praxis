# Contributing to Praxis

Want to work on Praxis? Here are instructions to get you started. Please let us
know if anything feels wrong or incomplete.

## Reporting Issues

When reporting [issues](https://github.com/rightscale/praxis/issues) on GitHub,
remember to include your Ruby version.

Please also include the steps required to reproduce the problem if possible and
applicable. This information will help us review and fix your issue faster.

## Contribution guidelines

### Project Goals

Before submitting any contributions, please read the below description of what
the problems Praxis aims to solve. Contributions that are not aligned with
Praxis' goals will not be accepted.

Praxis is a web framework for developing usable, consistent and
self-documenting HTTP APIs for
[SOA](http://en.wikipedia.org/wiki/Service-oriented_architecture) systems.

Praxis is not a Rails plugin or extension. If you want to use Praxis with
Rails, please create a separate gem or equivalent. We will not enhance Praxis
with Rails-specific functionality.

Praxis is also not designed for service any kind of UI, although UIs can
certainly be powered by Praxis apps.

### Pull requests are always welcome

We are always thrilled to receive pull requests, and do our best to process
them as fast as possible. Not sure if that typo is worth a pull request? Do it!
We will appreciate it.

If your pull request is not accepted on the first try, don't be discouraged! If
there's a problem with the implementation, hopefully you received feedback on
what to improve.

We're trying very hard to keep Praxis lean and focused. We don't want it to do
everything for everybody. This means that we might decide against incorporating
a new feature. However, there might be a way to implement that feature *on top
of* Praxis.

### Discuss your design on the mailing list

We recommend discussing your plans on the
[praxis-development](http://groups.google.com/d/forum/praxis-development)
mailing list before starting to code - especially for more ambitious
contributions. This gives other contributors a chance to point you in the right
direction, provide feedback on your design, and maybe point out if someone else
is working on the same thing.

### Create issues...

Any significant improvement should be documented as [a GitHub
issue](https://github.com/rightscale/praxis/issues) before anybody starts
working on it.

### ...but check for existing issues first!

Please take a moment to check that an issue doesn't already exist
documenting your bug report or improvement proposal. If it does, it
never hurts to add a quick "+1" or "I have this problem too". This will
help prioritize the most common problems and requests.

### Conventions

Fork the repository and make changes on your fork in a feature branch:

- If it's a bug fix branch, name it XXXX-something where XXXX is the number of
  the issue.
- If it's a feature branch, create an enhancement issue to announce your
  intentions, and name it XXXX-something where XXXX is the number of the issue.

Submit unit tests for your changes. Take a look at existing tests for
inspiration. Run the full test suite on your branch before submitting a pull
request.

Update the documentation when creating or modifying features. Test your
documentation changes for clarity, concision, and correctness.

Pull requests descriptions should be as clear as possible and include a
reference to all the issues that they address.

Pull requests must not contain commits from other users or branches.

Commit messages must start with a capitalized and short summary (max. 50 chars)
written in the imperative, followed by an optional, more detailed explanatory
text which is separated from the summary by an empty line.

Code review comments may be added to your pull request. Discuss, then make the
suggested modifications and push additional commits to your feature branch. Be
sure to post a comment after pushing. The new commits will show up in the pull
request automatically, but the reviewers will not be notified unless you
comment.

Before the pull request is merged, make sure that you squash your commits into
logical units of work using `git rebase -i` and `git push -f`. After every
commit the test suite should be passing. Include documentation changes in the
same commit so that a revert would remove all traces of the feature or fix.

Commits that fix or close an issue should include a reference like
`Closes #XXXX` or `Fixes #XXXX`, which will automatically close the issue when
merged.

Please do not add yourself to the `AUTHORS` file unless you are on the Praxis
github team.

### Sign your work

The sign-off is a simple line at the end of the explanation for the
patch, which certifies that you wrote it or otherwise have the right to
pass it on as an open-source patch.  The rules are pretty simple: if you
can certify the below (from
[developercertificate.org](http://developercertificate.org/)):

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
660 York Street, Suite 102,
San Francisco, CA 94110 USA

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.

Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

Then you just add a line to every git commit message:

Signed-off-by: Joe Smith <joe.smith@email.com> Using your real name
(sorry, no pseudonyms or anonymous contributions.)

If you set your user.name and user.email git configs, you can sign your
commit automatically with git commit -s.

#### Small patch exception

There are several exceptions to the signing requirement. Currently these are:

* Your patch fixes spelling or grammar errors.
* Your patch is a single line change to documentation.
* Your patch fixes Markdown formatting or syntax errors in the documentation.

### How can I become a maintainer?

* Step 1: Learn the component inside out
* Step 2: Make yourself useful by contributing code, bug fixes, support etc.
* Step 3: Volunteer on the [praxis-development mailing list](http://groups.google.com/d/forum/praxis-development)

Don't forget: being a maintainer is a time investment. Make sure you will have
time to make yourself available.  You don't have to be a maintainer to make a
difference on the project!

