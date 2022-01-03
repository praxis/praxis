# Contributing to Praxis

Want to work on Praxis? Here are instructions to get you started. Please let us
know if anything feels wrong or incomplete.

## Reporting Issues

When reporting [issues](https://github.com/praxis/praxis/issues) on GitHub,
remember to include your Ruby version.

Please also include the steps required to reproduce the problem if possible and
applicable. This information will help us review and fix your issue faster.

## Contribution guidelines

### Project Goals

Before submitting any contributions, please read the below description of what
the problems Praxis aims to solve. Contributions that are not aligned with
Praxis' goals will not be accepted.

Praxis is not a Rails plugin or extension. If you want to use Praxis with
Rails, please look at the MiddlewareApp class on how to embed it on an existing Rails project.

Praxis is also not designed for service any kind of UI, although UIs can
certainly be powered by Praxis apps.

### Pull requests are always welcome

We are always thrilled to receive pull requests, and do our best to process
them as fast as possible. Not sure if that typo is worth a pull request? Do it!
We will appreciate it.

We're trying very hard to keep Praxis lean and focused. We don't want it to do
everything for everybody. This means that we might decide against incorporating
a new feature. However, there might be a way to implement that feature *on top
of* Praxis.

If you want to work on something that we have already reviewed and prepared,
checkout the *Ready* column on our [Waffle board](https://waffle.io/praxis/praxis).

### Discuss your design on the mailing list

We recommend discussing your plans on the
[praxis-development](http://groups.google.com/d/forum/praxis-development)
mailing list before starting to code - especially for more ambitious
contributions. This gives other contributors a chance to point you in the right
direction, provide feedback on your design, and maybe point out if someone else
is working on the same thing.

### Create issues...

Any significant improvement should be documented as [a GitHub
issue](https://github.com/praxis/praxis/issues) before anybody starts
working on it.

### ...but check for existing issues first!

Please take a moment to check that an issue doesn't already exist
documenting your bug report or improvement proposal. If it does, it
never hurts to add a quick "+1" or "I have this problem too". This will
help prioritize the most common problems and requests.

### Conventions

Fork the repository and make changes on your fork in a feature branch.
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

Add a quick summary of your change to the changelog, under the `next` heading.

### How can I become a maintainer?

* Step 1: Learn the component inside out
* Step 2: Make yourself useful by contributing code, bug fixes, support etc.
* Step 3: Volunteer on the [praxis-development mailing list](http://groups.google.com/d/forum/praxis-development)

Don't forget: being a maintainer is a time investment. Make sure you will have
time to make yourself available.  You don't have to be a maintainer to make a
difference on the project!
