#!/bin/bash
set -eo pipefail

M=100   # for gradient tests
N=10000  # for sampling tests

ls src/test/basic     | grep '\.birch' | sed "s/.birch$/ -N $N/g"              | xargs -t -L 1 birch
ls src/test/cdf       | grep '\.birch' | sed "s/.birch$/ -N $N/g"              | xargs -t -L 1 birch
ls src/test/grad      | grep '\.birch' | sed "s/.birch$/ -N $M/g"              | xargs -t -L 1 birch
ls src/test/pdf       | grep '\.birch' | sed "s/.birch$/ -N $N --lazy false/g" | xargs -t -L 1 birch
ls src/test/pdf       | grep '\.birch' | sed "s/.birch$/ -N $N --lazy true/g"  | xargs -t -L 1 birch
ls src/test/conjugacy | grep '\.birch' | sed "s/.birch$/ -N $N --lazy false/g" | xargs -t -L 1 birch
ls src/test/conjugacy | grep '\.birch' | sed "s/.birch$/ -N $N --lazy true/g"  | xargs -t -L 1 birch
