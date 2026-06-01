# LinkedIn Lookup

A small Mac program that does one job. Drag a person's name into its little window; it asks the web who they might be on LinkedIn; you pick from a short list; their profile opens in your browser. That is the whole of it.

I made it because the alternatives are worse. The growth tools that pass for LinkedIn automation today will find a stranger, visit the page, and send a connection request without your hand ever touching the keyboard. They are mostly forbidden by LinkedIn's terms of service, they get accounts restricted with some regularity, and they have a tedious habit of pestering the wrong person in your name. This program does none of those things. It finds candidates. It stops there. Whether to connect with any of them — and how you would like to introduce yourself — is left to you, where it belongs.

## Install

A single line will do it:

```sh
curl -fsSL https://raw.githubusercontent.com/johnnyryan/linkedin-lookup/main/install.sh | sh
```

That downloads the latest release, puts `LinkedInLookup.app` in your `Applications` folder, and opens it. macOS 13 or later. If you would rather read the script before piping it into your shell — a sensible habit — it lives [here](install.sh).

## Build from source

If you would rather compile it yourself, or you want to change something, you need the Apple command-line tools:

```sh
xcode-select --install   # skip if you already have them
git clone https://github.com/johnnyryan/linkedin-lookup.git
cd linkedin-lookup
./build.sh
open LinkedInLookup.app
```

A small floating window appears and sits above your other windows. Drag a selected name onto the dashed box — or type one and press Return. Click any candidate and that profile opens in your default browser. `⌘Q` quits.

For testing the search engine on its own, without the window:

```sh
.build/release/LinkedInLookup --search "Satya Nadella"
```

## What it does

- Takes a name, either dragged in from any application or typed.
- Asks Brave Search for `site:linkedin.com/in "Name"`.
- Lists the candidates with whatever scrap of context Brave returns — a job title, a company, a country — enough to tell one John Smith from another.
- Opens the profile you click. Nothing more.

## What it does not do

- It does not log in to LinkedIn on your behalf.
- It does not send connection requests, messages, or anything else from your account.
- It does not record the names you look up.
- It makes no contact with any server other than the search engine itself.

## A note on the candidates

The list is only as good as Brave's index of LinkedIn's public pages. Common names yield long lists; specific names yield short and useful ones; nonsense yields whatever rubbish the engine happens to return. This is the honest state of free web search and there is no point pretending otherwise.

If you would like cleaner results, the resolver lives in [a single file](Sources/LinkedInLookup/Resolver.swift) and could be pointed at a paid lookup service — RocketReach, ContactOut, Proxycurl, or whatever the present fashion is — that returns proper structured data and accepts an email address as input. I have not done so. The point was a tool that runs on an unburdened machine, with no API keys and no accounts.

## Licence

MIT. Copyright (c) 2026 Johnny Ryan. See [`LICENSE`](LICENSE).
