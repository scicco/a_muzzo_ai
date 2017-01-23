A MUZZO A.I.
================
### Purposes
Help you create balanced table football teams.

### Features
- Percentile calculation of votes to find balanced random teams.
- Min and Max range of votes with incremental adjustments 

### How to use

build dependencies with 

```shell
bundle install
```
create the following files based on the examples:

- roles.yml
- vote.yml
- jokes.yml (it optional but funny)
 

Create a Google Form Questionary with each Player name and role as question and use values of votes.yml 
as available responses

example:

- John (Role: INDIFFERENT)  
- Marc (Role: ATTACKER) 
- James (Role: DEFENDER)

Save the Google Form questionnary result as responses.csv inside the root folder
(check the example for format)

This should like this:

|        Timestamp     |       Email address   | John (Role: INDIFFERENT)  | Marc (Role: ATTACKER) | ... |
|:--------------------:|:---------------------:|:-------------------------:|:---------------------:|:--- |
|  01/01/2017 00:00    |  john_doe@example.com |        CHAMPION           |        GOOD           | ... |


Notes:
> Each column name must contain the preferred role inside the name

>If using different weights please adjust @min_strength_bound and @max_strength_bound variables inside shuffler.rb start method (defaults are 6 and 12)

###Run

Run with 
```shell
ruby runner.rb <NUMBER OF PLAYERS>
```
> NUMBER OF PLAYERS is 16 by default

Enjoy!

###License

MIT
