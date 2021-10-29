# recordr [![Build Status](https://img.shields.io/github/workflow/status/bkahlert/recordr/build?label=Build&logo=github&logoColor=fff)](https://github.com/bkahlert/recordr/actions/workflows/build-and-publish.yml) [![Repository Size](https://img.shields.io/github/repo-size/bkahlert/recordr?color=01818F&label=Repo%20Size&logo=Git&logoColor=fff)](https://github.com/bkahlert/recordr) [![Repository Size](https://img.shields.io/github/license/bkahlert/recordr?color=29ABE2&label=License&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1OTAgNTkwIiAgeG1sbnM6dj0iaHR0cHM6Ly92ZWN0YS5pby9uYW5vIj48cGF0aCBkPSJNMzI4LjcgMzk1LjhjNDAuMy0xNSA2MS40LTQzLjggNjEuNC05My40UzM0OC4zIDIwOSAyOTYgMjA4LjljLTU1LjEtLjEtOTYuOCA0My42LTk2LjEgOTMuNXMyNC40IDgzIDYyLjQgOTQuOUwxOTUgNTYzQzEwNC44IDUzOS43IDEzLjIgNDMzLjMgMTMuMiAzMDIuNCAxMy4yIDE0Ny4zIDEzNy44IDIxLjUgMjk0IDIxLjVzMjgyLjggMTI1LjcgMjgyLjggMjgwLjhjMCAxMzMtOTAuOCAyMzcuOS0xODIuOSAyNjEuMWwtNjUuMi0xNjcuNnoiIGZpbGw9IiNmZmYiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIxOS4yMTIiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz48L3N2Zz4%3D)](https://github.com/bkahlert/recordr/blob/master/LICENSE)

## About
**Recordr** is an automated terminal session recorder and to SVG converter. 

[![recorded terminal session showing different image to character conversion settings](docs/chafa.svg "chafa")  
recorded chafa](../../raw/master/docs/chafa.svg)

[![recorded terminal session showing logr](docs/logr.svg "logr")  
recorded logr](../../raw/master/docs/logr.svg)

## Installation

`recordr` is a Bash library. 

In order to use it, it needs to be downloaded and put on your `$PATH`
which is exactly what the following line is doing:
```shell
sudo curl -LfsSo /usr/local/bin/recordr.sh https://raw.githubusercontent.com/bkahlert/recordr/master/recordr.sh
```

## Usage

```shell
# recordr.sh needs to be sourced to be used
source recordr.sh

# sample calls
recordr info "recordr.sh sourced"
recordr task "do some work" -- sleep 2
```

```shell
# invoke as binary for a feature overview
chmod +x recordr.sh
./recordr.sh

# help
./recordr.sh --help
```


## Testing

```shell
git clone https://github.com/bkahlert/recordr.git
cd recordr

# Use Bats wrapper to run tests
chmod +x ./batsw
./batsw test
```

`batsw` is a wrapper for the Bash testing framework [Bats](https://github.com/bats-core/bats-core).   
It builds a Docker image on-the-fly containing Bats incl. several libraries and runs all tests
contained in the specified directory.

> 💡 To accelerate testing, the Bats Wrapper checks if any test is prefixed with a capital X and if so, only runs those tests.


## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star the project, or to raise issues. You
can also support this project by making
a [Paypal donation](https://www.paypal.me/bkahlert) to ensure this journey continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:


## License

MIT. See [LICENSE](LICENSE) for more details.
