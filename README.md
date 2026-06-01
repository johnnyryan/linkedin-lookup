# LinkedIn Lookup

A tiny mac programme to search for people on linkedin. 

Drag a name in to its little window and it returns a list of possible Linkedin profiles. You select the person. Their profile opens in your browser. 

## Install

A single line:

```sh
curl -fsSL https://raw.githubusercontent.com/johnnyryan/linkedin-lookup/main/install.sh | sh
```

That downloads the latest release, puts `LinkedInLookup.app` in your `Applications` folder, and opens it. macOS 13 or later. If you would rather read the script before piping it into your shell it lives [here](install.sh).

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

Takes a name, either dragged in from any application or typed.
Asks Brave Search for `site:linkedin.com/in "Name"`.
Lists the candidates with whatever scrap of context Brave returns - a job title, a company, a country — enough to tell one Keyser Soze from another.
Opens the profile you click. Nothing more.

## What it does not do

It does not log in to LinkedIn on your behalf.
It does not send connection requests, messages, or anything else from your account.
It does not record the names you look up.
It makes no contact with any server other than the search engine itself.

## Licence

MIT. Copyright (c) 2026 Johnny Ryan. See [`LICENSE`](LICENSE).
