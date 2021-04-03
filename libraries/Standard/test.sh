#!/bin/bash
set -eo pipefail

P=1
M=1000    # for gradient tests
N=100000  # for sampling tests

ls src/test/basic     | grep '\.birch' | sed "s/.birch$/ -N $N/g"              | xargs -t -L 1 -P $P birch
ls src/test/cdf       | grep '\.birch' | sed "s/.birch$/ -N $N/g"              | xargs -t -L 1 -P $P birch
ls src/test/grad      | grep '\.birch' | sed "s/.birch$/ -N $M/g"              | xargs -t -L 1 -P $P birch
ls src/test/pdf       | grep '\.birch' | sed "s/.birch$/ -N $N --lazy false/g" | xargs -t -L 1 -P $P birch
ls src/test/pdf       | grep '\.birch' | sed "s/.birch$/ -N $N --lazy true/g"  | xargs -t -L 1 -P $P birch
ls src/test/conjugacy | grep '\.birch' | sed "s/.birch$/ -N $N --lazy false/g" | xargs -t -L 1 -P $P birch
ls src/test/conjugacy | grep '\.birch' | sed "s/.birch$/ -N $N --lazy true/g"  | xargs -t -L 1 -P $P birch
