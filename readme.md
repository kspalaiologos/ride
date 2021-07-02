# RIDE

**WARNING: THIS IS NOT THE OFFICIAL REPOSITORY. IT CONTAINS A BUNCH OF MY PATCHES. THEY ARE LICENSED SEPARATELY FROM RIDE, UNDER THE [AGPLv3 LICENSE](https://www.gnu.org/licenses/agpl-3.0.txt).**

RIDE is a remote IDE for [Dyalog](www.dyalog.com) APL.

![Screenshot](/screenshot.png?raw=true)

## Getting started

Install [Git](https://git-scm.com/downloads) and [NodeJS v10.13.0](https://nodejs.org/download/release/v10.13.0/)

    git clone https://github.com/kspalaiologos/ride --depth=1
    cd ride
    npm i         # download dependencies
    npm start     # start RIDE (without building native apps)
    node mk dist  # build native apps under _/ride${version}/
    node mk c     # cleans your build directory

(`#` starts a comment)
