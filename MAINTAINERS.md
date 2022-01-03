# The Praxis Maintainer manual

## Introduction

Dear maintainer. Thank you for investing the time and energy to help
make Praxis as useful as possible. Maintaining a project is difficult,
sometimes unrewarding work. Sure, you will get to contribute cool
features to the project. But most of your time will be spent reviewing,
cleaning up, documenting, answering questions, and justifying design
decisions - while everyone has all the fun! But remember - the quality
of the maintainers' work is what distinguishes the good projects from
the great. So please be proud of your work, even the unglamourous parts,
and encourage a culture of appreciation and respect for *every* aspect
of improving the project - not just the hot new features.

This document is a manual for maintainers old and new. It explains what
is expected of maintainers, how they should work, and what tools are
available to them.

This is a living document - if you see something out of date or missing,
speak up!

## What is a maintainer's responsibility?

It is every maintainer's responsibility to:

1. Expose a clear road map for improving their component.
2. Deliver prompt feedback and decisions on pull requests.
3. Be available to anyone with questions, bug reports, criticism etc.
  on their component. This includes GitHub requests and the mailing
  list.
4. Make sure their component respects the philosophy, design and
  road map of the project.
5. Be inclusive of the different ways to develop and use the framework

## How are decisions made?

Short answer: with pull requests to the Praxis repository.

Praxis is an open-source project with an open design philosophy. This
means that the repository is the source of truth for EVERY aspect of the
project, including its philosophy, design, road map, and APIs. *If it's
part of the project, it's in the repo. If it's in the repo, it's part of
the project.*

As a result, all decisions can be expressed as changes to the
repository. An implementation change is a change to the source code. An
API change is a change to the API specification. A philosophy change is
a change to the philosophy manifesto, and so on.

All decisions affecting Praxis, big and small, follow the same 3 steps:

* Step 1: Open a pull request. Anyone can do this.

* Step 2: Discuss the pull request. Anyone can do this.

* Step 3: Accept or refuse a pull request. The relevant maintainers do
this (see below "Who decides what?")


## Who decides what?

All decisions are pull requests, and the relevant maintainers make
decisions by accepting or refusing pull requests.

Praxis follows the timeless, highly efficient and totally unfair system
known as [Benevolent dictator for
life](http://en.wikipedia.org/wiki/Benevolent_Dictator_for_Life), with
Josep Blanquer (@blanquer), in the role of BDFL. This means that all
decisions are made, by default, by Josep. Since Josep making every
decision would be highly un-scalable, in practice decisions are spread
across multiple maintainers.

The list of maintainers is kept in the MAINTAINERS file

### I'm a maintainer. Should I make pull requests too?

Yes. Nobody should ever push to master directly. All changes should be
made through a pull request.

### Who assigns maintainers?

Josep has final approval for all pull requests to `MAINTAINERS` files.

### How is this process changed?

Just like everything else: by making a pull request :)
