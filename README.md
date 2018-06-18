###What it is

So-called jump service (public gateway) to access deep-web resouces from a regular web. Completely self-hosted and FOSS, written in perl.

###Why it exists

Existing public services [caught](https://www.bleepingcomputer.com/news/security/tor-to-web-proxy-caught-replacing-bitcoin-addresses-on-ransomware-payment-sites) doing nasty stuff for their own profit and are not trustworthy.

###Installation

Clone this repository:

```
git clone <path-to-repo>
cd repo
```

Install dependencies:

```
cd src
perl cpanm --installdeps .
```

Start service:

```
plackup bin/app.psgi
```

Access service on the port 5000; Note: this project does not provide implementations of tor or i2p networks itself. You need to install desirable onion and i2p routers using preferable method for your operating system and have it up and running for a gateway to work.

###To-Do

Make front page more eye-candy.

Prepare docker file to simplify deployment procedure.

Move important currently hardcoded stuff to a config file.